package report

import (
	"encoding/json"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const (
	divider    = "================================================================================"
	subDivider = "  ------------------------------------------------------------------------------"
	asterisks  = "********************************************************************************"
	author     = "Moskov - SrBalduR"
	version    = "NETAUDIT v1.0"
)

// ReportType identifies which module generated the report.
type ReportType string

const (
	TypeHostDiscovery ReportType = "host_discovery"
	TypePortScan      ReportType = "port_scan"
	TypeBannerGrab    ReportType = "banner_grab"
	TypeLocalSockets  ReportType = "local_sockets"
	TypeFirewall      ReportType = "firewall"
	TypeFullAudit     ReportType = "full_audit"
)

// ReportMeta holds metadata common to all reports.
type ReportMeta struct {
	Timestamp time.Time
	Type      ReportType
	Title     string
}

// WriteReport generates and writes a report file to the results directory.
// It writes the executive header in plain text followed by the raw JSON data.
func WriteReport(resultsDir string, meta ReportMeta, headerFunc func(*strings.Builder), jsonData interface{}) (string, error) {
	// Ensure results directory exists
	if err := os.MkdirAll(resultsDir, 0755); err != nil {
		return "", fmt.Errorf("no se pudo crear directorio de resultados: %w", err)
	}

	// Generate filename with timestamp
	ts := meta.Timestamp.Format("2006-01-02_150405")
	filename := fmt.Sprintf("%s_%s.txt", string(meta.Type), ts)
	outputPath := filepath.Join(resultsDir, filename)

	var sb strings.Builder

	// Write executive header
	writeCommonHeader(&sb, meta)
	headerFunc(&sb)

	// Asterisks divider before JSON
	sb.WriteString("\n")
	sb.WriteString(asterisks)
	sb.WriteString("\n\n")

	// Write JSON data
	jsonBytes, err := json.MarshalIndent(jsonData, "", "  ")
	if err != nil {
		return "", fmt.Errorf("error al serializar JSON: %w", err)
	}
	sb.Write(jsonBytes)
	sb.WriteString("\n")

	// Write file
	if err := os.WriteFile(outputPath, []byte(sb.String()), 0644); err != nil {
		return "", fmt.Errorf("error al escribir reporte: %w", err)
	}

	return outputPath, nil
}

// writeCommonHeader writes the standard report header block.
func writeCommonHeader(sb *strings.Builder, meta ReportMeta) {
	sb.WriteString(divider)
	sb.WriteString("\n\n")
	sb.WriteString(fmt.Sprintf("  %s - REPORTE DE AUDITORÍA: %s\n", version, meta.Title))
	sb.WriteString(fmt.Sprintf("\n  Desarrollado por: %s\n", author))
	sb.WriteString("\n")
	sb.WriteString(divider)
	sb.WriteString("\n\n")
	sb.WriteString(fmt.Sprintf("  [i] Fecha/Hora       : %s\n", meta.Timestamp.Format("2006-01-02 15:04:05")))
}

// ResolveHostname attempts a reverse DNS lookup (PTR record) for an IP address.
// Returns "No identificado" if resolution fails.
func ResolveHostname(ip string) string {
	names, err := net.LookupAddr(ip)
	if err != nil || len(names) == 0 {
		return "No identificado"
	}
	// Remove trailing dot from FQDN
	hostname := strings.TrimSuffix(names[0], ".")
	if hostname == "" {
		return "No identificado"
	}
	return hostname
}
