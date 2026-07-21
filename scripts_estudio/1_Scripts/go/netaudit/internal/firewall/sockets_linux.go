//go:build linux

package firewall

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

// GetListeningSockets returns all local sockets in LISTEN state with PID/process info.
// Uses /proc/net/tcp and ss/netstat as fallback on Linux.
func GetListeningSockets() ([]ListenSocket, error) {
	// Try ss first (modern, faster)
	sockets, err := getSocketsViaSS()
	if err == nil && len(sockets) > 0 {
		return sockets, nil
	}

	// Fallback to netstat
	return getSocketsViaNetstat()
}

// getSocketsViaSS uses the `ss` command to list listening sockets.
func getSocketsViaSS() ([]ListenSocket, error) {
	out, err := exec.Command("ss", "-tlnp").Output()
	if err != nil {
		return nil, fmt.Errorf("ss command failed: %w", err)
	}

	var sockets []ListenSocket
	scanner := bufio.NewScanner(strings.NewReader(string(out)))
	scanner.Scan() // Skip header

	for scanner.Scan() {
		line := scanner.Text()
		sock := parseSSLine(line, "tcp")
		if sock != nil {
			sockets = append(sockets, *sock)
		}
	}

	// Also get UDP listeners
	out, err = exec.Command("ss", "-ulnp").Output()
	if err == nil {
		scanner = bufio.NewScanner(strings.NewReader(string(out)))
		scanner.Scan() // Skip header
		for scanner.Scan() {
			line := scanner.Text()
			sock := parseSSLine(line, "udp")
			if sock != nil {
				sockets = append(sockets, *sock)
			}
		}
	}

	return sockets, nil
}

// parseSSLine parses a single line from `ss -tlnp` or `ss -ulnp` output.
func parseSSLine(line, protocol string) *ListenSocket {
	fields := strings.Fields(line)
	if len(fields) < 5 {
		return nil
	}

	// Local address is typically at index 3 (State Recv-Q Send-Q Local)
	localAddr := fields[3]
	port := extractPort(localAddr)
	if port == 0 {
		return nil
	}

	addr := extractAddress(localAddr)

	// Process info is in the last field, format: users:(("process",pid=XXX,fd=Y))
	pid := 0
	process := ""
	for _, f := range fields {
		if strings.Contains(f, "pid=") {
			pid, process = parsePIDFromSS(f)
			break
		}
	}

	return &ListenSocket{
		Protocol: protocol,
		Address:  addr,
		Port:     port,
		PID:      pid,
		Process:  process,
	}
}

// parsePIDFromSS extracts PID and process name from ss output.
// Format: users:(("sshd",pid=1234,fd=3))
func parsePIDFromSS(field string) (int, string) {
	pid := 0
	process := ""

	// Extract process name
	if idx := strings.Index(field, "((\""); idx != -1 {
		end := strings.Index(field[idx+3:], "\"")
		if end != -1 {
			process = field[idx+3 : idx+3+end]
		}
	}

	// Extract PID
	if idx := strings.Index(field, "pid="); idx != -1 {
		numStr := ""
		for _, c := range field[idx+4:] {
			if c >= '0' && c <= '9' {
				numStr += string(c)
			} else {
				break
			}
		}
		pid, _ = strconv.Atoi(numStr)
	}

	return pid, process
}

// getSocketsViaNetstat uses netstat as fallback.
func getSocketsViaNetstat() ([]ListenSocket, error) {
	out, err := exec.Command("netstat", "-tlnp").Output()
	if err != nil {
		return nil, fmt.Errorf("netstat command failed: %w", err)
	}

	var sockets []ListenSocket
	scanner := bufio.NewScanner(strings.NewReader(string(out)))

	// Skip header lines
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "tcp") || strings.HasPrefix(line, "udp") {
			sock := parseNetstatLine(line)
			if sock != nil {
				sockets = append(sockets, *sock)
			}
		}
	}

	return sockets, nil
}

// parseNetstatLine parses a netstat -tlnp output line.
func parseNetstatLine(line string) *ListenSocket {
	fields := strings.Fields(line)
	if len(fields) < 7 {
		return nil
	}

	protocol := fields[0]
	localAddr := fields[3]
	pidProg := fields[6]

	port := extractPort(localAddr)
	if port == 0 {
		return nil
	}

	addr := extractAddress(localAddr)
	pid, process := parseNetstatPID(pidProg)

	return &ListenSocket{
		Protocol: protocol,
		Address:  addr,
		Port:     port,
		PID:      pid,
		Process:  process,
	}
}

// parseNetstatPID parses "PID/program" from netstat output.
func parseNetstatPID(pidProg string) (int, string) {
	if pidProg == "-" {
		return 0, ""
	}
	parts := strings.SplitN(pidProg, "/", 2)
	if len(parts) < 2 {
		return 0, ""
	}
	pid, _ := strconv.Atoi(parts[0])
	return pid, parts[1]
}

// extractPort extracts the port number from an address string like "0.0.0.0:22" or ":::22".
func extractPort(addr string) int {
	idx := strings.LastIndex(addr, ":")
	if idx == -1 {
		return 0
	}
	portStr := addr[idx+1:]
	port, err := strconv.Atoi(portStr)
	if err != nil {
		return 0
	}
	return port
}

// extractAddress extracts the address portion from "addr:port".
func extractAddress(addr string) string {
	idx := strings.LastIndex(addr, ":")
	if idx == -1 {
		return addr
	}
	a := addr[:idx]
	if a == "*" || a == "" {
		return "0.0.0.0"
	}
	return a
}

// GetProcessName returns the process name for a given PID.
func GetProcessName(pid int) string {
	commPath := fmt.Sprintf("/proc/%d/comm", pid)
	data, err := os.ReadFile(commPath)
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(data))
}
