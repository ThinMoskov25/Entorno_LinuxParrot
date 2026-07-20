package scanner

import "time"

// Host represents a discovered host on the network.
type Host struct {
	IP       string `json:"ip"`
	MAC      string `json:"mac,omitempty"`
	Vendor   string `json:"vendor,omitempty"`
	Method   string `json:"method"` // "arp" or "icmp"
	RTT      time.Duration `json:"rtt_ns,omitempty"`
}

// PortResult represents the result of scanning a single port.
type PortResult struct {
	Port    int    `json:"port"`
	State   string `json:"state"` // "open", "closed", "filtered"
	Service string `json:"service,omitempty"`
	Banner  string `json:"banner,omitempty"`
}

// ScanConfig holds configuration for network scanning operations.
type ScanConfig struct {
	Target      string
	PortRange   string // e.g. "1-1024" or "22,80,443"
	Timeout     time.Duration
	Concurrency int
}

// DefaultPorts defines common ports to scan when no custom range is specified.
var DefaultPorts = []int{
	21, 22, 23, 25, 53, 80, 110, 111, 135, 139,
	143, 443, 445, 993, 995, 1723, 3306, 3389,
	5900, 8080, 8443,
}
