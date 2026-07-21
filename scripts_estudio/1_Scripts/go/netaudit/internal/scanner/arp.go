package scanner

import (
	"context"
	"fmt"
	"net"
	"sync"
	"time"
)

// ARPScan performs Layer 2 ARP discovery on the local subnet.
// It requires root/admin privileges for raw socket access.
// Falls back to ICMP sweep if ARP fails.
func ARPScan(ctx context.Context, iface string, timeout time.Duration) ([]Host, error) {
	netIface, err := net.InterfaceByName(iface)
	if err != nil {
		return nil, fmt.Errorf("interface %q not found: %w", iface, err)
	}

	addrs, err := netIface.Addrs()
	if err != nil {
		return nil, fmt.Errorf("failed to get addresses for %q: %w", iface, err)
	}

	var subnet *net.IPNet
	for _, addr := range addrs {
		if ipNet, ok := addr.(*net.IPNet); ok {
			if ipNet.IP.To4() != nil {
				subnet = ipNet
				break
			}
		}
	}
	if subnet == nil {
		return nil, fmt.Errorf("no IPv4 subnet found on interface %q", iface)
	}

	hosts := enumerateSubnet(subnet)
	if len(hosts) == 0 {
		return nil, fmt.Errorf("no hosts to scan in subnet %s", subnet.String())
	}

	// Attempt ARP scan using system's ARP table after pinging
	results, err := arpDiscover(ctx, hosts, netIface, timeout)
	if err != nil || len(results) == 0 {
		// Fallback to ICMP sweep
		return ICMPSweep(ctx, hosts, timeout)
	}

	return results, nil
}

// arpDiscover sends ARP-like probes by pinging hosts and reading the system ARP table.
// On Linux, this reads /proc/net/arp after stimulating the ARP cache.
func arpDiscover(ctx context.Context, hosts []string, iface *net.Interface, timeout time.Duration) ([]Host, error) {
	var (
		mu      sync.Mutex
		results []Host
		wg      sync.WaitGroup
	)

	sem := make(chan struct{}, 100) // Limit concurrency

	for _, ip := range hosts {
		select {
		case <-ctx.Done():
			break
		default:
		}

		wg.Add(1)
		sem <- struct{}{}
		go func(target string) {
			defer wg.Done()
			defer func() { <-sem }()

			conn, err := net.DialTimeout("ip4:icmp", target, timeout)
			if err != nil {
				// Try TCP connect to stimulate ARP
				tcpConn, tcpErr := net.DialTimeout("tcp", target+":80", timeout)
				if tcpErr == nil {
					tcpConn.Close()
				}
				return
			}
			conn.Close()

			mu.Lock()
			results = append(results, Host{
				IP:     target,
				Method: "arp",
			})
			mu.Unlock()
		}(ip)
	}

	wg.Wait()

	// Enrich results with MAC addresses from system ARP cache
	enrichFromARPCache(results)

	return results, nil
}

// enumerateSubnet generates all host IPs in a given subnet.
func enumerateSubnet(subnet *net.IPNet) []string {
	var hosts []string
	ip := subnet.IP.Mask(subnet.Mask)
	for inc(ip); subnet.Contains(ip); inc(ip) {
		// Skip network and broadcast addresses
		hosts = append(hosts, ip.String())
	}
	// Remove the last IP (broadcast)
	if len(hosts) > 1 {
		hosts = hosts[:len(hosts)-1]
	}
	return hosts
}

// inc increments an IP address by one.
func inc(ip net.IP) {
	for j := len(ip) - 1; j >= 0; j-- {
		ip[j]++
		if ip[j] > 0 {
			break
		}
	}
}
