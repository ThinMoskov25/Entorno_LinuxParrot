package scanner

import (
	"context"
	"fmt"
	"net"
	"strconv"
	"strings"
	"sync"
	"time"
)

// ScanPorts performs an asynchronous TCP port scan on the target host.
// Uses goroutines and channels for maximum concurrency with configurable limits.
func ScanPorts(ctx context.Context, cfg ScanConfig) ([]PortResult, error) {
	ports, err := parsePorts(cfg.PortRange)
	if err != nil {
		return nil, err
	}

	if cfg.Concurrency <= 0 {
		cfg.Concurrency = 500
	}
	if cfg.Timeout <= 0 {
		cfg.Timeout = 2 * time.Second
	}

	var (
		mu      sync.Mutex
		results []PortResult
		wg      sync.WaitGroup
	)

	// Buffered channel as semaphore for concurrency control
	sem := make(chan struct{}, cfg.Concurrency)
	// Channel to collect results
	resultCh := make(chan PortResult, len(ports))

	// Launch scanner goroutines
	for _, port := range ports {
		select {
		case <-ctx.Done():
			break
		default:
		}

		wg.Add(1)
		sem <- struct{}{}
		go func(p int) {
			defer wg.Done()
			defer func() { <-sem }()

			result := scanSinglePort(ctx, cfg.Target, p, cfg.Timeout)
			if result.State == "open" {
				resultCh <- result
			}
		}(port)
	}

	// Close result channel when all goroutines complete
	go func() {
		wg.Wait()
		close(resultCh)
	}()

	// Collect results from channel
	for result := range resultCh {
		mu.Lock()
		results = append(results, result)
		mu.Unlock()
	}

	return results, nil
}

// scanSinglePort probes a single TCP port on the target.
func scanSinglePort(ctx context.Context, target string, port int, timeout time.Duration) PortResult {
	result := PortResult{
		Port:    port,
		State:   "closed",
		Service: identifyService(port),
	}

	address := fmt.Sprintf("%s:%d", target, port)
	dialer := net.Dialer{Timeout: timeout}

	conn, err := dialer.DialContext(ctx, "tcp", address)
	if err != nil {
		// Differentiate between filtered and closed
		if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
			result.State = "filtered"
		}
		return result
	}
	defer conn.Close()

	result.State = "open"
	return result
}

// parsePorts parses a port range string into a slice of port numbers.
// Supports: "80", "1-1024", "22,80,443", "1-100,443,8080-8090"
func parsePorts(portRange string) ([]int, error) {
	if portRange == "" {
		return DefaultPorts, nil
	}

	var ports []int
	segments := strings.Split(portRange, ",")

	for _, seg := range segments {
		seg = strings.TrimSpace(seg)
		if strings.Contains(seg, "-") {
			parts := strings.SplitN(seg, "-", 2)
			start, err := strconv.Atoi(strings.TrimSpace(parts[0]))
			if err != nil {
				return nil, fmt.Errorf("invalid port range start: %q", parts[0])
			}
			end, err := strconv.Atoi(strings.TrimSpace(parts[1]))
			if err != nil {
				return nil, fmt.Errorf("invalid port range end: %q", parts[1])
			}
			if start < 1 || end > 65535 || start > end {
				return nil, fmt.Errorf("invalid port range: %d-%d", start, end)
			}
			for p := start; p <= end; p++ {
				ports = append(ports, p)
			}
		} else {
			p, err := strconv.Atoi(seg)
			if err != nil {
				return nil, fmt.Errorf("invalid port number: %q", seg)
			}
			if p < 1 || p > 65535 {
				return nil, fmt.Errorf("port out of range: %d", p)
			}
			ports = append(ports, p)
		}
	}

	return ports, nil
}

// identifyService returns the common service name for well-known ports.
func identifyService(port int) string {
	services := map[int]string{
		21:   "FTP",
		22:   "SSH",
		23:   "Telnet",
		25:   "SMTP",
		53:   "DNS",
		80:   "HTTP",
		110:  "POP3",
		111:  "RPCBind",
		135:  "MSRPC",
		139:  "NetBIOS",
		143:  "IMAP",
		443:  "HTTPS",
		445:  "SMB",
		993:  "IMAPS",
		995:  "POP3S",
		1723: "PPTP",
		3306: "MySQL",
		3389: "RDP",
		5432: "PostgreSQL",
		5900: "VNC",
		6379: "Redis",
		8080: "HTTP-Proxy",
		8443: "HTTPS-Alt",
		27017: "MongoDB",
	}

	if svc, ok := services[port]; ok {
		return svc
	}
	return ""
}
