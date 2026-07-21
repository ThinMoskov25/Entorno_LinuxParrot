package report

import (
	"fmt"
	"strings"
	"time"

	"github.com/moskov/netaudit/internal/banner"
	"github.com/moskov/netaudit/internal/firewall"
	"github.com/moskov/netaudit/internal/scanner"
)

// FullAuditJSON is the JSON payload for a complete audit report.
type FullAuditJSON struct {
	Timestamp string                  `json:"timestamp"`
	Action    string                  `json:"action"`
	Target    string                  `json:"target"`
	Interface string                  `json:"interface,omitempty"`
	Hosts     []HostEntry             `json:"hosts,omitempty"`
	Ports     []scanner.PortResult    `json:"ports,omitempty"`
	Banners   []*banner.Result        `json:"banners,omitempty"`
	Sockets   []firewall.ListenSocket `json:"sockets,omitempty"`
}

// FullAuditData holds all data gathered during a full audit for the report.
type FullAuditData struct {
	Target    string
	Interface string
	Hosts     []scanner.Host
	Ports     []scanner.PortResult
	Banners   []*banner.Result
	Sockets   []firewall.ListenSocket
}

// ExportFullAudit generates the comprehensive audit report with executive header.
func ExportFullAudit(resultsDir string, data FullAuditData) (string, error) {
	now := time.Now()

	meta := ReportMeta{
		Timestamp: now,
		Type:      TypeFullAudit,
		Title:     "AUDITORÍA COMPLETA DE RED",
	}

	// Resolve hostnames for hosts
	hostEntries := make([]HostEntry, 0, len(data.Hosts))
	for _, h := range data.Hosts {
		hostname := ResolveHostname(h.IP)
		mac := h.MAC
		if mac == "" {
			mac = "N/A"
		}
		vendorStr := h.Vendor
		if vendorStr == "" {
			vendorStr = "Desconocido"
		}
		hostEntries = append(hostEntries, HostEntry{
			IP:       h.IP,
			Hostname: hostname,
			MAC:      mac,
			Vendor:   vendorStr,
			Method:   h.Method,
		})
	}

	// Count insecure banners
	insecureCount := 0
	for _, b := range data.Banners {
		if !b.Secure {
			insecureCount++
		}
	}

	headerFunc := func(sb *strings.Builder) {
		sb.WriteString(fmt.Sprintf("  [i] Objetivo         : %s\n", data.Target))
		if data.Interface != "" {
			sb.WriteString(fmt.Sprintf("  [i] Interfaz usada   : %s\n", data.Interface))
		}
		sb.WriteString(fmt.Sprintf("  [i] Hosts detectados : %d\n", len(data.Hosts)))
		sb.WriteString(fmt.Sprintf("  [i] Puertos abiertos : %d\n", len(data.Ports)))
		sb.WriteString(fmt.Sprintf("  [i] Servicios anal.  : %d\n", len(data.Banners)))
		sb.WriteString(fmt.Sprintf("  [i] Sockets locales  : %d\n", len(data.Sockets)))
		if insecureCount > 0 {
			sb.WriteString(fmt.Sprintf("  [!] Alertas seguridad: %d servicio(s) inseguro(s)\n", insecureCount))
		}
		sb.WriteString("\n")
		sb.WriteString(divider)
		sb.WriteString("\n")

		// Section 1: Hosts
		if len(hostEntries) > 0 {
			sb.WriteString("\n  FASE 1 - DISPOSITIVOS EN LA RED:\n")
			sb.WriteString("\n")
			sb.WriteString(subDivider)
			sb.WriteString("\n")
			for _, entry := range hostEntries {
				sb.WriteString(fmt.Sprintf("\n  [+] IP: %s\n", entry.IP))
				sb.WriteString(fmt.Sprintf("      Nombre      : %s\n", entry.Hostname))
				sb.WriteString(fmt.Sprintf("      MAC         : %s\n", entry.MAC))
				sb.WriteString(fmt.Sprintf("      Fabricante  : %s\n", entry.Vendor))
			}
			sb.WriteString("\n")
			sb.WriteString(subDivider)
			sb.WriteString("\n")
		}

		// Section 2: Ports
		if len(data.Ports) > 0 {
			sb.WriteString("\n  FASE 2 - PUERTOS ABIERTOS:\n\n")
			for _, p := range data.Ports {
				svc := p.Service
				if svc == "" {
					svc = "desconocido"
				}
				sb.WriteString(fmt.Sprintf("  [+] Puerto %d  -  Servicio: %s  -  Estado: %s\n", p.Port, svc, p.State))
			}
			sb.WriteString("\n")
			sb.WriteString(subDivider)
			sb.WriteString("\n")
		}

		// Section 3: Banners
		if len(data.Banners) > 0 {
			sb.WriteString("\n  FASE 3 - ANÁLISIS DE SERVICIOS:\n\n")
			for _, b := range data.Banners {
				status := "SEGURO"
				if !b.Secure {
					status = "⚠ INSEGURO"
				}
				sb.WriteString(fmt.Sprintf("  [+] %s (Puerto %d): %s [%s]\n", b.Service, b.Port, b.Banner, status))
				if b.Details != "" {
					sb.WriteString(fmt.Sprintf("      Detalles: %s\n", b.Details))
				}
			}
			sb.WriteString("\n")
			sb.WriteString(subDivider)
			sb.WriteString("\n")
		}

		// Section 4: Local Sockets
		if len(data.Sockets) > 0 {
			sb.WriteString("\n  FASE 4 - SOCKETS LOCALES EN ESCUCHA:\n\n")
			for _, s := range data.Sockets {
				proc := s.Process
				if proc == "" {
					proc = "(desconocido)"
				}
				sb.WriteString(fmt.Sprintf("  [+] %s:%d (%s) - PID: %d - Proceso: %s\n",
					s.Address, s.Port, s.Protocol, s.PID, proc))
			}
			sb.WriteString("\n")
			sb.WriteString(subDivider)
			sb.WriteString("\n")
		}

		// Conclusions
		sb.WriteString("\n  CONCLUSIÓN:\n\n")
		sb.WriteString(fmt.Sprintf("    Se auditó el objetivo %s con los siguientes resultados:\n", data.Target))
		sb.WriteString(fmt.Sprintf("    • %d dispositivo(s) detectado(s) en la red\n", len(data.Hosts)))
		sb.WriteString(fmt.Sprintf("    • %d puerto(s) abierto(s)\n", len(data.Ports)))
		sb.WriteString(fmt.Sprintf("    • %d servicio(s) analizado(s)\n", len(data.Banners)))
		if insecureCount > 0 {
			sb.WriteString(fmt.Sprintf("    • ⚠ %d servicio(s) con problemas de seguridad detectados\n", insecureCount))
		} else if len(data.Banners) > 0 {
			sb.WriteString("    • Todos los servicios analizados parecen seguros\n")
		}
		sb.WriteString("\n")
	}

	jsonPayload := FullAuditJSON{
		Timestamp: now.Format(time.RFC3339),
		Action:    string(TypeFullAudit),
		Target:    data.Target,
		Interface: data.Interface,
		Hosts:     hostEntries,
		Ports:     data.Ports,
		Banners:   data.Banners,
		Sockets:   data.Sockets,
	}

	return WriteReport(resultsDir, meta, headerFunc, jsonPayload)
}
