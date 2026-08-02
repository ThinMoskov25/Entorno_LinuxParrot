package report

import (
	"fmt"
	"strings"
	"time"

	"github.com/moskov/netaudit/internal/firewall"
)

// LocalSocketsJSON is the JSON payload for local sockets reports.
type LocalSocketsJSON struct {
	Timestamp    string                  `json:"timestamp"`
	Action       string                  `json:"action"`
	TotalListen  int                     `json:"total_listen"`
	Sockets      []firewall.ListenSocket `json:"sockets"`
}

// FirewallOpJSON represents a firewall operation result for the report.
type FirewallOpJSON struct {
	Timestamp  string                `json:"timestamp"`
	Action     string                `json:"action"`
	Operations []firewall.RuleResult `json:"operations"`
}

// ExportLocalSockets generates the local sockets report with executive header.
func ExportLocalSockets(resultsDir string, sockets []firewall.ListenSocket) (string, error) {
	now := time.Now()

	meta := ReportMeta{
		Timestamp: now,
		Type:      TypeLocalSockets,
		Title:     "SOCKETS LOCALES EN ESCUCHA",
	}

	// Collect unique processes
	processMap := make(map[string]int) // process -> count
	for _, s := range sockets {
		proc := s.Process
		if proc == "" {
			proc = "(desconocido)"
		}
		processMap[proc]++
	}

	// Collect unique PIDs
	pidSet := make(map[int]bool)
	for _, s := range sockets {
		if s.PID > 0 {
			pidSet[s.PID] = true
		}
	}

	headerFunc := func(sb *strings.Builder) {
		sb.WriteString(fmt.Sprintf("  [i] Total en escucha : %d puerto(s)\n", len(sockets)))
		sb.WriteString(fmt.Sprintf("  [i] Procesos únicos  : %d\n", len(processMap)))
		sb.WriteString(fmt.Sprintf("  [i] PIDs activos     : %d\n", len(pidSet)))
		sb.WriteString("\n")
		sb.WriteString(divider)
		sb.WriteString("\n\n")
		sb.WriteString("  PROCESOS CON PUERTOS EN ESCUCHA:\n")
		sb.WriteString("\n")
		sb.WriteString(subDivider)
		sb.WriteString("\n\n")

		// Summary by process
		sb.WriteString("  Resumen por proceso:\n\n")
		for proc, count := range processMap {
			sb.WriteString(fmt.Sprintf("    • %s: %d puerto(s)\n", proc, count))
		}
		sb.WriteString("\n")

		// Detailed listing
		sb.WriteString("  Detalle de sockets:\n\n")
		for _, s := range sockets {
			proc := s.Process
			if proc == "" {
				proc = "(desconocido)"
			}
			pidStr := fmt.Sprintf("%d", s.PID)
			if s.PID == 0 {
				pidStr = "-"
			}
			sb.WriteString(fmt.Sprintf("  [+] %s:%d (%s)\n", s.Address, s.Port, s.Protocol))
			sb.WriteString(fmt.Sprintf("      PID       : %s\n", pidStr))
			sb.WriteString(fmt.Sprintf("      Proceso   : %s\n", proc))
			sb.WriteString("\n")
		}

		sb.WriteString(subDivider)
		sb.WriteString("\n")
	}

	jsonPayload := LocalSocketsJSON{
		Timestamp:   now.Format(time.RFC3339),
		Action:      string(TypeLocalSockets),
		TotalListen: len(sockets),
		Sockets:     sockets,
	}

	return WriteReport(resultsDir, meta, headerFunc, jsonPayload)
}

// ExportFirewallOps generates the firewall operations report with executive header.
func ExportFirewallOps(resultsDir string, operations []firewall.RuleResult) (string, error) {
	now := time.Now()

	meta := ReportMeta{
		Timestamp: now,
		Type:      TypeFirewall,
		Title:     "OPERACIONES DE FIREWALL",
	}

	// Count successes and failures
	successCount := 0
	failCount := 0
	for _, op := range operations {
		if op.Success {
			successCount++
		} else {
			failCount++
		}
	}

	headerFunc := func(sb *strings.Builder) {
		sb.WriteString(fmt.Sprintf("  [i] Total operaciones : %d\n", len(operations)))
		sb.WriteString(fmt.Sprintf("  [i] Exitosas          : %d\n", successCount))
		sb.WriteString(fmt.Sprintf("  [i] Fallidas          : %d\n", failCount))
		sb.WriteString("\n")
		sb.WriteString(divider)
		sb.WriteString("\n\n")
		sb.WriteString("  REGLAS DE FIREWALL APLICADAS:\n")
		sb.WriteString("\n")
		sb.WriteString(subDivider)
		sb.WriteString("\n")

		for i, op := range operations {
			status := "✓ ÉXITO"
			if !op.Success {
				status = "✗ FALLO"
			}
			sb.WriteString(fmt.Sprintf("\n  [%d] Regla: %s puerto %d/%s (dirección: %s)\n",
				i+1, op.Rule.Action, op.Rule.Port, op.Rule.Protocol, op.Rule.Dir))
			sb.WriteString(fmt.Sprintf("      Estado    : %s\n", status))
			sb.WriteString(fmt.Sprintf("      Comando   : %s\n", op.Command))
			sb.WriteString(fmt.Sprintf("      Mensaje   : %s\n", op.Message))
		}

		sb.WriteString("\n")
		sb.WriteString(subDivider)
		sb.WriteString("\n")
	}

	jsonPayload := FirewallOpJSON{
		Timestamp:  now.Format(time.RFC3339),
		Action:     string(TypeFirewall),
		Operations: operations,
	}

	return WriteReport(resultsDir, meta, headerFunc, jsonPayload)
}
