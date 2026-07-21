//go:build windows

package firewall

import (
	"bufio"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

// GetListeningSockets returns all local sockets in LISTEN state on Windows.
// Uses netstat -ano to get socket info and tasklist for process names.
func GetListeningSockets() ([]ListenSocket, error) {
	out, err := exec.Command("netstat", "-ano").Output()
	if err != nil {
		return nil, fmt.Errorf("netstat command failed: %w", err)
	}

	var sockets []ListenSocket
	scanner := bufio.NewScanner(strings.NewReader(string(out)))

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Only process LISTENING entries
		if !strings.Contains(line, "LISTENING") {
			continue
		}

		sock := parseWindowsNetstatLine(line)
		if sock != nil {
			sockets = append(sockets, *sock)
		}
	}

	return sockets, nil
}

// parseWindowsNetstatLine parses a Windows netstat -ano output line.
// Format: Proto  Local Address          Foreign Address        State           PID
func parseWindowsNetstatLine(line string) *ListenSocket {
	fields := strings.Fields(line)
	if len(fields) < 5 {
		return nil
	}

	protocol := strings.ToLower(fields[0])
	localAddr := fields[1]
	// state is fields[3]
	pidStr := fields[4]

	port := extractPort(localAddr)
	if port == 0 {
		return nil
	}

	addr := extractAddress(localAddr)
	pid, _ := strconv.Atoi(pidStr)
	process := GetProcessName(pid)

	return &ListenSocket{
		Protocol: protocol,
		Address:  addr,
		Port:     port,
		PID:      pid,
		Process:  process,
	}
}

// extractPort extracts the port from a Windows address format like "0.0.0.0:135" or "[::]:135".
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
	if a == "0.0.0.0" || a == "[::1]" || a == "[::]" {
		return "0.0.0.0"
	}
	return a
}

// GetProcessName returns the process name for a given PID on Windows.
func GetProcessName(pid int) string {
	out, err := exec.Command("tasklist", "/FI",
		fmt.Sprintf("PID eq %d", pid), "/FO", "CSV", "/NH").Output()
	if err != nil {
		return ""
	}
	line := strings.TrimSpace(string(out))
	if line == "" || strings.Contains(line, "No tasks") {
		return ""
	}
	// CSV format: "process.exe","PID",...
	parts := strings.Split(line, ",")
	if len(parts) > 0 {
		return strings.Trim(parts[0], "\"")
	}
	return ""
}
