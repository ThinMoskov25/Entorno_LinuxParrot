//go:build windows

package scanner

import (
	"os/exec"
	"strings"
)

// enrichFromARPCache reads the ARP cache on Windows using "arp -a".
func enrichFromARPCache(hosts []Host) {
	out, err := exec.Command("arp", "-a").Output()
	if err != nil {
		return
	}

	// Build a lookup map
	ipToIdx := make(map[string]int, len(hosts))
	for i, h := range hosts {
		ipToIdx[h.IP] = i
	}

	lines := strings.Split(string(out), "\n")
	for _, line := range lines {
		fields := strings.Fields(strings.TrimSpace(line))
		if len(fields) < 3 {
			continue
		}
		ip := fields[0]
		mac := strings.ReplaceAll(fields[1], "-", ":")

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
