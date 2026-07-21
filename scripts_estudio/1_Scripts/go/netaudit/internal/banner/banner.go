package banner

import (
	"bufio"
	"fmt"
	"net"
	"strings"
	"time"
)

// Result holds the banner grabbing result for a service.
type Result struct {
	Host    string `json:"host"`
	Port    int    `json:"port"`
	Service string `json:"service"`
	Banner  string `json:"banner"`
	Version string `json:"version,omitempty"`
	Secure  bool   `json:"secure"`
	Details string `json:"details,omitempty"`
}

// Grab connects to a host:port and attempts to read the service banner.
// It applies service-specific logic for SSH (port 22) and FTP (port 21).
func Grab(host string, port int, timeout time.Duration) (*Result, error) {
	if timeout <= 0 {
		timeout = 5 * time.Second
	}

	address := fmt.Sprintf("%s:%d", host, port)
	conn, err := net.DialTimeout("tcp", address, timeout)
	if err != nil {
		return nil, fmt.Errorf("connection to %s failed: %w", address, err)
	}
	defer conn.Close()

	conn.SetReadDeadline(time.Now().Add(timeout))

	result := &Result{
		Host:    host,
		Port:    port,
		Service: identifyServiceName(port),
		Secure:  true, // Assume secure until proven otherwise
	}

	switch port {
	case 22:
		return grabSSH(conn, result)
	case 21:
		return grabFTP(conn, result)
	default:
		return grabGeneric(conn, result)
	}
}

// grabGeneric reads a single line banner from any TCP service.
func grabGeneric(conn net.Conn, result *Result) (*Result, error) {
	reader := bufio.NewReader(conn)
	line, err := reader.ReadString('\n')
	if err != nil {
		// Some services don't send a banner until prompted
		fmt.Fprintf(conn, "\r\n")
		conn.SetReadDeadline(time.Now().Add(2 * time.Second))
		line, err = reader.ReadString('\n')
		if err != nil {
			result.Banner = "(no banner)"
			return result, nil
		}
	}

	result.Banner = sanitizeBanner(line)
	return result, nil
}

// sanitizeBanner cleans up a raw banner string.
func sanitizeBanner(raw string) string {
	s := strings.TrimSpace(raw)
	// Remove control characters
	var clean strings.Builder
	for _, r := range s {
		if r >= 32 && r < 127 {
			clean.WriteRune(r)
		}
	}
	return clean.String()
}

// identifyServiceName maps port numbers to service names.
func identifyServiceName(port int) string {
	services := map[int]string{
		21:   "FTP",
		22:   "SSH",
		23:   "Telnet",
		25:   "SMTP",
		80:   "HTTP",
		110:  "POP3",
		143:  "IMAP",
		443:  "HTTPS",
		3306: "MySQL",
		5432: "PostgreSQL",
		6379: "Redis",
	}
	if svc, ok := services[port]; ok {
		return svc
	}
	return "Unknown"
}
