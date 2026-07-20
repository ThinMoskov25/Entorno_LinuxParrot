package banner

import (
	"bufio"
	"fmt"
	"net"
	"strings"
	"time"
)

// SSHInfo contains detailed SSH service information.
type SSHInfo struct {
	Version     string `json:"version"`
	Software    string `json:"software"`
	Protocol    string `json:"protocol"`
	KeyExchange string `json:"key_exchange,omitempty"`
	Deprecated  bool   `json:"deprecated"`
}

// grabSSH performs SSH-specific banner grabbing and version identification.
func grabSSH(conn net.Conn, result *Result) (*Result, error) {
	reader := bufio.NewReader(conn)

	// SSH servers send their version string immediately upon connection
	line, err := reader.ReadString('\n')
	if err != nil {
		result.Banner = "(SSH: no response)"
		result.Secure = false
		return result, nil
	}

	banner := sanitizeBanner(line)
	result.Banner = banner

	// Parse SSH version string: SSH-<protocol>-<software> <comments>
	info := parseSSHBanner(banner)
	result.Version = info.Software
	result.Details = fmt.Sprintf("Protocol: %s, Software: %s", info.Protocol, info.Software)

	// Security checks
	checkSSHSecurity(info, result)

	return result, nil
}

// parseSSHBanner parses an SSH identification string.
// Format: SSH-protoversion-softwareversion SP comments CR LF
func parseSSHBanner(banner string) SSHInfo {
	info := SSHInfo{}

	if !strings.HasPrefix(banner, "SSH-") {
		info.Software = banner
		return info
	}

	parts := strings.SplitN(banner, "-", 3)
	if len(parts) < 3 {
		info.Software = banner
		return info
	}

	info.Protocol = parts[1]

	// Software version may have a space-separated comment
	softwareParts := strings.SplitN(parts[2], " ", 2)
	info.Software = softwareParts[0]
	info.Version = fmt.Sprintf("SSH-%s-%s", info.Protocol, info.Software)

	// Check for deprecated protocol versions
	if info.Protocol == "1.0" || info.Protocol == "1.5" || info.Protocol == "1.99" {
		info.Deprecated = true
	}

	return info
}

// checkSSHSecurity performs lightweight security checks on the SSH service.
func checkSSHSecurity(info SSHInfo, result *Result) {
	var issues []string

	// Check for deprecated SSH protocol versions
	if info.Deprecated {
		issues = append(issues, fmt.Sprintf("WARN: Deprecated SSH protocol %s detected", info.Protocol))
		result.Secure = false
	}

	// Check for known vulnerable software versions
	software := strings.ToLower(info.Software)

	// OpenSSH versions below 7.0 have known vulnerabilities
	if strings.Contains(software, "openssh") {
		version := extractOpenSSHVersion(software)
		if version != "" && isVulnerableOpenSSH(version) {
			issues = append(issues, fmt.Sprintf("WARN: Potentially vulnerable OpenSSH version: %s", version))
			result.Secure = false
		}
	}

	// Check for Dropbear older versions
	if strings.Contains(software, "dropbear") {
		issues = append(issues, "INFO: Dropbear SSH detected - verify version is current")
	}

	if len(issues) > 0 {
		result.Details += " | " + strings.Join(issues, "; ")
	}
}

// extractOpenSSHVersion extracts the version number from an OpenSSH banner.
func extractOpenSSHVersion(software string) string {
	// Pattern: OpenSSH_X.Yp1 or openssh_x.y
	idx := strings.Index(software, "openssh_")
	if idx == -1 {
		idx = strings.Index(software, "openssh_")
	}
	if idx == -1 {
		return ""
	}

	versionStr := software[idx+8:]
	// Extract until non-version character
	var version strings.Builder
	for _, c := range versionStr {
		if (c >= '0' && c <= '9') || c == '.' {
			version.WriteRune(c)
		} else {
			break
		}
	}
	return version.String()
}

// isVulnerableOpenSSH checks if an OpenSSH version has known vulnerabilities.
func isVulnerableOpenSSH(version string) bool {
	// Major.Minor parsing
	parts := strings.Split(version, ".")
	if len(parts) < 2 {
		return false
	}

	major := 0
	minor := 0
	fmt.Sscanf(parts[0], "%d", &major)
	fmt.Sscanf(parts[1], "%d", &minor)

	// Versions below 7.0 have significant known vulnerabilities
	if major < 7 {
		return true
	}
	// Versions 7.x below 7.4 have some issues
	if major == 7 && minor < 4 {
		return true
	}
	return false
}

// ProbeSSH performs an active SSH probe with version identification.
func ProbeSSH(host string, timeout time.Duration) (*Result, error) {
	return Grab(host, 22, timeout)
}
