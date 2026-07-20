package banner

import (
	"bufio"
	"fmt"
	"net"
	"strings"
	"time"
)

// FTPInfo contains detailed FTP service information.
type FTPInfo struct {
	Banner         string `json:"banner"`
	Version        string `json:"version"`
	AnonymousLogin bool   `json:"anonymous_login"`
	ResponseCode   string `json:"response_code"`
}

// grabFTP performs FTP-specific banner grabbing and anonymous login check.
func grabFTP(conn net.Conn, result *Result) (*Result, error) {
	reader := bufio.NewReader(conn)

	// Read FTP welcome banner (220 response)
	banner, err := readFTPResponse(reader)
	if err != nil {
		result.Banner = "(FTP: no response)"
		result.Secure = false
		return result, nil
	}

	result.Banner = sanitizeBanner(banner)
	result.Version = extractFTPVersion(banner)

	// Test anonymous login
	anonResult := testAnonymousLogin(conn, reader)
	if anonResult {
		result.Secure = false
		result.Details = "CRITICAL: Anonymous FTP login ALLOWED - security risk"
	} else {
		result.Details = "OK: Anonymous FTP login denied"
	}

	return result, nil
}

// readFTPResponse reads a complete FTP response (may be multi-line).
func readFTPResponse(reader *bufio.Reader) (string, error) {
	var response strings.Builder

	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			if response.Len() > 0 {
				return response.String(), nil
			}
			return "", err
		}

		response.WriteString(line)

		// FTP multi-line responses use "XXX-" prefix, final line uses "XXX "
		if len(line) >= 4 && line[3] == ' ' {
			break
		}
		// Also break if it's a simple response
		if len(line) >= 4 && line[3] != '-' {
			break
		}
	}

	return response.String(), nil
}

// testAnonymousLogin attempts to authenticate as anonymous to the FTP server.
func testAnonymousLogin(conn net.Conn, reader *bufio.Reader) bool {
	// Send USER anonymous
	conn.SetWriteDeadline(time.Now().Add(5 * time.Second))
	_, err := fmt.Fprintf(conn, "USER anonymous\r\n")
	if err != nil {
		return false
	}

	// Read response (expect 331 for password prompt or 230 for immediate access)
	conn.SetReadDeadline(time.Now().Add(5 * time.Second))
	response, err := readFTPResponse(reader)
	if err != nil {
		return false
	}

	response = strings.TrimSpace(response)

	// 230 = logged in without password
	if strings.HasPrefix(response, "230") {
		return true
	}

	// 331 = password required, try anonymous password
	if strings.HasPrefix(response, "331") {
		conn.SetWriteDeadline(time.Now().Add(5 * time.Second))
		_, err = fmt.Fprintf(conn, "PASS anonymous@test.com\r\n")
		if err != nil {
			return false
		}

		conn.SetReadDeadline(time.Now().Add(5 * time.Second))
		passResponse, err := readFTPResponse(reader)
		if err != nil {
			return false
		}

		// 230 = login successful
		if strings.HasPrefix(strings.TrimSpace(passResponse), "230") {
			// Send QUIT to be polite
			fmt.Fprintf(conn, "QUIT\r\n")
			return true
		}
	}

	return false
}

// extractFTPVersion attempts to extract version info from FTP banner.
func extractFTPVersion(banner string) string {
	lower := strings.ToLower(banner)

	knownServers := []string{
		"vsftpd", "proftpd", "pure-ftpd", "filezilla",
		"microsoft ftp", "wu-ftpd", "serv-u",
	}

	for _, server := range knownServers {
		if idx := strings.Index(lower, server); idx != -1 {
			// Extract the server name and version
			end := idx + len(server)
			// Try to get version number after server name
			remaining := banner[end:]
			version := extractVersionNumber(remaining)
			if version != "" {
				return server + " " + version
			}
			return server
		}
	}

	return ""
}

// extractVersionNumber extracts a version number from a string.
func extractVersionNumber(s string) string {
	s = strings.TrimSpace(s)
	var version strings.Builder
	started := false

	for _, c := range s {
		if (c >= '0' && c <= '9') || c == '.' {
			version.WriteRune(c)
			started = true
		} else if started {
			break
		}
	}

	return version.String()
}

// ProbeFTP performs an active FTP probe with anonymous login test.
func ProbeFTP(host string, timeout time.Duration) (*Result, error) {
	return Grab(host, 21, timeout)
}
