package scanner

import (
	"fmt"
	"net"
	"os"
	"runtime"
)

// GetDefaultInterface returns the name of the default network interface.
func GetDefaultInterface() (string, error) {
	ifaces, err := net.Interfaces()
	if err != nil {
		return "", fmt.Errorf("failed to list interfaces: %w", err)
	}

	for _, iface := range ifaces {
		// Skip loopback and down interfaces
		if iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		if iface.Flags&net.FlagUp == 0 {
			continue
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			if ipNet, ok := addr.(*net.IPNet); ok && ipNet.IP.To4() != nil {
				if !ipNet.IP.IsLoopback() {
					return iface.Name, nil
				}
			}
		}
	}

	return "", fmt.Errorf("no suitable network interface found")
}

// CheckPrivileges verifies that the process has root/admin privileges.
func CheckPrivileges() error {
	switch runtime.GOOS {
	case "linux", "darwin":
		if os.Geteuid() != 0 {
			return fmt.Errorf("this operation requires root privileges (run with sudo)")
		}
	case "windows":
		// On Windows, check for admin by attempting to open a protected path
		_, err := os.Open("\\\\.\\PHYSICALDRIVE0")
		if err != nil {
			return fmt.Errorf("this operation requires Administrator privileges")
		}
	}
	return nil
}

// GetLocalIP returns the local machine's primary IPv4 address.
func GetLocalIP() (string, error) {
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		return "", err
	}
	defer conn.Close()

	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP.String(), nil
}
