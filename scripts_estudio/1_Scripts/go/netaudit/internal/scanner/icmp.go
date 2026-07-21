package scanner

import (
	"context"
	"net"
	"sync"
	"time"
)

// ICMPSweep performs concurrent ICMP echo requests as fallback discovery.
// Uses TCP connect probes on common ports as an alternative to raw ICMP
// (which requires elevated privileges on some systems).
func ICMPSweep(ctx context.Context, hosts []string, timeout time.Duration) ([]Host, error) {
	var (
		mu      sync.Mutex
		results []Host
		wg      sync.WaitGroup
	)

	// Use a semaphore to limit concurrency
	sem := make(chan struct{}, 200)
	probePorts := []string{":80", ":443", ":22", ":445"}

	for _, ip := range hosts {
		select {
		case <-ctx.Done():
			return results, ctx.Err()
		default:
		}

		wg.Add(1)
		sem <- struct{}{}
		go func(target string) {
			defer wg.Done()
			defer func() { <-sem }()

			start := time.Now()
			alive := false

			// Try ICMP-like probe using UDP on unlikely port
			conn, err := net.DialTimeout("udp4", target+":33434", timeout)
			if err == nil {
				conn.Close()
			}

			// TCP connect probe on common ports
			for _, port := range probePorts {
				select {
				case <-ctx.Done():
					return
				default:
				}
				tcpConn, err := net.DialTimeout("tcp", target+port, timeout)
				if err == nil {
					tcpConn.Close()
					alive = true
					break
				}
			}

			if alive {
				rtt := time.Since(start)
				mu.Lock()
				results = append(results, Host{
					IP:     target,
					Method: "icmp",
					RTT:    rtt,
				})
				mu.Unlock()
			}
		}(ip)
	}

	wg.Wait()
	return results, nil
}
