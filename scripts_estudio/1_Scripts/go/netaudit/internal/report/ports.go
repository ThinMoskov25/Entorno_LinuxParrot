package report

import (
	"fmt"
	"strings"
	"time"

	"github.com/moskov/netaudit/internal/banner"
	"github.com/moskov/netaudit/internal/scanner"
)

// PortScanJSON is the JSON payload for port scan reports.
type PortScanJSON struct {
	Timestamp  string               `json:"timestamp"`
	Action     string               `json:"action"`
	Target     string               `json:"target"`
	TotalOpen  int                  `json:"total_open"`
	Ports      []scanner.PortResult `json:"ports"`
}

// BannerGrabJSON is the JSON payload for banner/service inspection reports.
type BannerGrabJSON struct {
	Timestamp string           `json:"timestamp"`
	Action    string           `json:"action"`
	Target    string           `json:"target"`
	Total     int              `json:"total_services"`
	Banners   []*banner.Result `json:"banners"`
}

// ExportPortScan generates the port scan report with executive header.
func ExportPortScan(resultsDir string, target string, ports []scanner.PortResult) (string, error) {
	now := time.Now()

	meta := ReportMeta{
		Timestamp: now,
		Type:      TypePortScan,
		Title:     "ESCANEO DE PUERTOS",
	}

	// Count services by type
	serviceCount := make(map[string]int)
	for _, p := range ports {
		svc := p.Service
		if svc == "" {
			svc = "desconocido"
		}
		serviceCount[svc]++
	}

	headerFunc := func(sb *strings.Builder) {
		sb.WriteString(fmt.Sprintf("  [i] Host auditado    : %s\n", target))
		sb.WriteString(fmt.Sprintf("  [i] Puertos abiertos : %d\n", len(ports)))
		sb.WriteString("\n")
		sb.WriteString(divider)
		sb.WriteString("\n\n")
		sb.WriteString("  RESUMEN DE PUERTOS Y SERVICIOS:\n")
		sb.WriteString("\n")
		sb.WriteString(subDivider)
		sb.WriteString("\n\n")

		// Services summary
		sb.WriteString("  Servicios detectados:\n\n")
		for svc, count := range serviceCount {
			sb.WriteString(fmt.Sprintf("    • %s: %d puerto(s)\n", svc, count))
		}
		sb.WriteString("\n")

		// Port listing
		sb.WriteString("  Detalle de puertos abiertos:\n\n")
		for _, p := range ports {
			svc := p.Service
			if svc == "" {
				svc = "desconocido"
			}
			sb.WriteString(fmt.Sprintf("  [+] Puerto %d/%s  -  Servicio: %s  -  Estado: %s\n", p.Port, "tcp", svc, p.State))
		}

		sb.WriteString("\n")
		sb.WriteString(subDivider)
		sb.WriteString("\n")
	}

	jsonPayload := PortScanJSON{
		Timestamp: now.Format(time.RFC3339),
		Action:    string(TypePortScan),
		Target:    target,
		TotalOpen: len(ports),
		Ports:     ports,
	}

	return WriteReport(resultsDir, meta, headerFunc, jsonPayload)
}

// ExportBannerGrab generates the banner/service inspection report with executive header.
func ExportBannerGrab(resultsDir string, target string, banners []*banner.Result) (string, error) {
	now := time.Now()

	meta := ReportMeta{
		Timestamp: now,
		Type:      TypeBannerGrab,
		Title:     "INSPECCIÓN DE SERVICIOS (BANNER GRAB)",
	}

	// Count secure vs insecure
	secureCount := 0
	insecureCount := 0
	for _, b := range banners {
		if b.Secure {
			secureCount++
		} else {
			insecureCount++
		}
	}

	headerFunc := func(sb *strings.Builder) {
		sb.WriteString(fmt.Sprintf("  [i] Host auditado    : %s\n", target))
		sb.WriteString(fmt.Sprintf("  [i] Servicios        : %d analizados\n", len(banners)))
		sb.WriteString(fmt.Sprintf("  [i] Seguros          : %d\n", secureCount))
		sb.WriteString(fmt.Sprintf("  [i] Inseguros        : %d\n", insecureCount))
		sb.WriteString("\n")
		sb.WriteString(divider)
		sb.WriteString("\n\n")
		sb.WriteString("  HALLAZGOS POR SERVICIO:\n")
		sb.WriteString("\n")
		sb.WriteString(subDivider)
		sb.WriteString("\n")

		for _, b := range banners {
			status := "SEGURO"
			if !b.Secure {
				status = "⚠ INSEGURO"
			}
			sb.WriteString(fmt.Sprintf("\n  [+] Servicio: %s (Puerto %d)\n", b.Service, b.Port))
			sb.WriteString(fmt.Sprintf("      Banner    : %s\n", b.Banner))
			if b.Version != "" {
				sb.WriteString(fmt.Sprintf("      Versión   : %s\n", b.Version))
			}
			if b.Details != "" {
				sb.WriteString(fmt.Sprintf("      Detalles  : %s\n", b.Details))
			}
			sb.WriteString(fmt.Sprintf("      Seguridad : %s\n", status))
		}

		sb.WriteString("\n")
		sb.WriteString(subDivider)
		sb.WriteString("\n")

		// Key findings
		if insecureCount > 0 {
			sb.WriteString("\n  ⚠ HALLAZGOS CLAVE:\n\n")
			for _, b := range banners {
				if !b.Secure {
					sb.WriteString(fmt.Sprintf("    • %s (Puerto %d): %s\n", b.Service, b.Port, b.Details))
				}
			}
			sb.WriteString("\n")
		}
	}

	jsonPayload := BannerGrabJSON{
		Timestamp: now.Format(time.RFC3339),
		Action:    string(TypeBannerGrab),
		Target:    target,
		Total:     len(banners),
		Banners:   banners,
	}

	return WriteReport(resultsDir, meta, headerFunc, jsonPayload)
}
