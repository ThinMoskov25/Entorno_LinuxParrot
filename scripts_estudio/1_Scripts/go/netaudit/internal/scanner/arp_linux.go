//go:build linux

package scanner

import (
	"bufio"
	"os"
	"strings"
)

// enrichFromARPCache reads /proc/net/arp on Linux to get MAC addresses.
func enrichFromARPCache(hosts []Host) {
	f, err := os.Open("/proc/net/arp")
	if err != nil {
		return
	}
	defer f.Close()

	// Build a lookup map
	ipToIdx := make(map[string]int, len(hosts))
	for i, h := range hosts {
		ipToIdx[h.IP] = i
	}

	scanner := bufio.NewScanner(f)
	scanner.Scan() // Skip header line

	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) < 4 {
			continue
		}
		ip := fields[0]
		mac := fields[3]

		if idx, ok := ipToIdx[ip]; ok {
			hosts[idx].MAC = mac
			hosts[idx].Vendor = lookupVendor(mac)
		}
	}
}

// lookupVendor identifies the NIC vendor from the MAC OUI prefix.
func lookupVendor(mac string) string {
	if len(mac) < 8 {
		return "Unknown"
	}
	oui := strings.ToUpper(mac[:8])

	// Common OUI prefixes (abbreviated database)
	vendors := map[string]string{
		"00:50:56": "VMware",
		"00:0C:29": "VMware",
		"08:00:27": "VirtualBox",
		"52:54:00": "QEMU/KVM",
		"DC:A6:32": "Raspberry Pi",
		"B8:27:EB": "Raspberry Pi",
		"00:1A:79": "Dell",
		"00:25:B5": "Dell",
		"3C:D9:2B": "HP",
		"00:1E:68": "Quanta",
		"F0:DE:F1": "Apple",
		"A4:83:E7": "Apple",
		"00:16:3E": "Xen",
		"00:15:5D": "Hyper-V",
		"AA:BB:CC": "Private",
	}

	if vendor, ok := vendors[oui]; ok {
		return vendor
	}
	return "Unknown"
}
