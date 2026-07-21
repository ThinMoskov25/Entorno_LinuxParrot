package report

import (
	"fmt"
	"strings"
	"time"

	"github.com/moskov/netaudit/internal/scanner"
)

// HostEntry represents a host with resolved hostname for the report.
type HostEntry struct {
	IP       string `json:"ip"`
	Hostname string `json:"hostname"`
	MAC      string `json:"mac"`
	Vendor   string `json:"vendor"`
	Method   string `json:"method,omitempty"`
}

// HostDiscoveryJSON is the JSON payload for host discovery reports.
type HostDiscoveryJSON struct {
	Timestamp string      `json:"timestamp"`
	Action    string      `json:"action"`
	Interface string      `json:"interface"`
	Total     int         `json:"total"`
	Hosts     []HostEntry `json:"hosts"`
}

// ExportHostDiscovery generates the host discovery report with executive header.
func ExportHostDiscovery(resultsDir string, iface string, hosts []scanner.Host) (string, error) {
	now := time.Now()

	// Resolve hostnames and build entries
	entries := make([]HostEntry, 0, len(hosts))
	for _, h := range hosts {
		hostname := ResolveHostname(h.IP)
		mac := h.MAC
		if mac == "" {
			mac = "N/A"
		}
		vendor := h.Vendor
		if vendor == "" {
			vendor = "Desconocido"
		}
		entries = append(entries, HostEntry{
			IP:       h.IP,
			Hostname: hostname,
			MAC:      mac,
			Vendor:   vendor,
			Method:   h.Method,
		})
	}

	meta := ReportMeta{
		Timestamp: now,
		Type:      TypeHostDiscovery,
		Title:     "DESCUBRIMIENTO DE HOSTS",
	}

	headerFunc := func(sb *strings.Builder) {
		sb.WriteString(fmt.Sprintf("  [i] Interfaz usada   : %s\n", iface))
		sb.WriteString(fmt.Sprintf("  [i] Total Hosts      : %d dispositivo(s) detectado(s)\n", len(entries)))
		sb.WriteString("\n")
		sb.WriteString(divider)
		sb.WriteString("\n\n")
		sb.WriteString("  RESUMEN DE DISPOSITIVOS DETECTADOS:\n")
		sb.WriteString("\n")
		sb.WriteString(subDivider)
		sb.WriteString("\n")

		for _, entry := range entries {
			sb.WriteString(fmt.Sprintf("\n  [+] IP: %s\n", entry.IP))
			sb.WriteString(fmt.Sprintf("      Nombre      : %s\n", entry.Hostname))
			sb.WriteString(fmt.Sprintf("      MAC         : %s\n", entry.MAC))
			sb.WriteString(fmt.Sprintf("      Fabricante  : %s\n", entry.Vendor))
			sb.WriteString(fmt.Sprintf("      Acción      : Para auditar este host ejecute opción 2 con IP %s\n", entry.IP))
		}

		sb.WriteString("\n")
		sb.WriteString(subDivider)
		sb.WriteString("\n")
	}

	jsonPayload := HostDiscoveryJSON{
		Timestamp: now.Format(time.RFC3339),
		Action:    string(TypeHostDiscovery),
		Interface: iface,
		Total:     len(entries),
		Hosts:     entries,
	}

	return WriteReport(resultsDir, meta, headerFunc, jsonPayload)
}
