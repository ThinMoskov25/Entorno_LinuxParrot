package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/moskov/netaudit/internal/banner"
	"github.com/moskov/netaudit/internal/cli"
	"github.com/moskov/netaudit/internal/firewall"
	"github.com/moskov/netaudit/internal/logger"
	"github.com/moskov/netaudit/internal/report"
	"github.com/moskov/netaudit/internal/scanner"
)

// resultsDir holds the path to the results directory.
var resultsDir string

// sessionData holds data accumulated during the session for reports.
var sessionData struct {
	iface   string
	target  string
	hosts   []scanner.Host
	ports   []scanner.PortResult
	banners []*banner.Result
	sockets []firewall.ListenSocket
	fwOps   []firewall.RuleResult
}

func main() {
	// Quick check: if "help" command, show usage without any initialization
	if len(os.Args) > 1 && (os.Args[1] == "help" || os.Args[1] == "--help" || os.Args[1] == "-h") {
		cli.PrintBanner()
		cli.PrintUsage()
		return
	}

	// Determine base directory (where the binary is executed)
	baseDir, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error al obtener directorio de trabajo: %v\n", err)
		os.Exit(1)
	}

	// Initialize logger (creates ./logs/ directory)
	if err := logger.Init(baseDir); err != nil {
		fmt.Fprintf(os.Stderr, "Error al inicializar logger: %v\n", err)
		os.Exit(1)
	}
	defer logger.Close()

	// Create results directory
	resultsDir = filepath.Join(baseDir, "results")
	if err := os.MkdirAll(resultsDir, 0755); err != nil {
		cli.PrintError("No se pudo crear directorio de resultados: %v", err)
		logger.Error("No se pudo crear directorio de resultados %q: %v", resultsDir, err)
		os.Exit(1)
	}
	logger.Info("Directorio de resultados: %s", resultsDir)

	// Check if running in command mode (arguments provided)
	cmd := cli.ParseArgs(os.Args)
	if cmd != nil {
		// Help doesn't need logger/results initialization
		if cmd.Name == cli.CmdHelp {
			cli.PrintBanner()
			cli.PrintUsage()
			return
		}
		cli.PrintBanner()
		logger.Info("Modo comando: %s", cmd.Name)
		runCommand(cmd)
		return
	}

	// Interactive mode (no arguments)
	cli.PrintBanner()

	menu := cli.NewMenu()

	for {
		choice := menu.ShowMainMenu()
		logger.Action("Opción seleccionada del menú: %s", choice)

		switch choice {
		case "1":
			runHostDiscovery(menu)
		case "2":
			runPortScan(menu)
		case "3":
			runBannerGrab(menu)
		case "4":
			runLocalSockets()
		case "5":
			runFirewallManagement(menu)
		case "6":
			runFullAudit(menu)
		case "7":
			exportReport(menu)
		case "0", "exit", "quit", "q", "salir":
			cli.PrintInfo("Saliendo de NetAudit. ¡Mantente seguro!")
			logger.Info("Usuario salió de la aplicación")
			os.Exit(0)
		default:
			cli.PrintError("Opción inválida: %s", choice)
			logger.Warn("Opción inválida ingresada: %s", choice)
		}
	}
}

// runCommand executes a subcommand directly from CLI arguments.
func runCommand(cmd *cli.Command) {
	switch cmd.Name {
	case cli.CmdHelp:
		cli.PrintUsage()

	case cli.CmdDiscover:
		cmdDiscover(cmd)

	case cli.CmdScan:
		cmdScan(cmd)

	case cli.CmdBanner:
		cmdBanner(cmd)

	case cli.CmdSockets:
		cmdSockets()

	case cli.CmdFirewall:
		cmdFirewall(cmd)

	case cli.CmdAudit:
		cmdAudit(cmd)
	}
}

// cmdDiscover executes host discovery from CLI flags.
func cmdDiscover(cmd *cli.Command) {
	cli.PrintSection("Descubrimiento de Hosts (Barrido ARP/ICMP)")
	logger.Action("Comando: discover")

	defaultIface, err := scanner.GetDefaultInterface()
	if err != nil {
		defaultIface = "eth0"
	}

	iface := cmd.GetFlag("iface", defaultIface)
	timeoutMs, _ := strconv.Atoi(cmd.GetFlag("timeout", "1000"))
	if timeoutMs <= 0 {
		timeoutMs = 1000
	}

	timeout := time.Duration(timeoutMs) * time.Millisecond
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	cli.PrintInfo("Escaneando subred en interfaz %s (timeout: %dms)...", iface, timeoutMs)
	logger.Info("Barrido ARP en interfaz %s con timeout %dms", iface, timeoutMs)
	fmt.Println()

	hosts, err := scanner.ARPScan(ctx, iface, timeout)
	if err != nil {
		cli.PrintError("Escaneo fallido: %v", err)
		logger.Error("Barrido ARP fallido: %v", err)
		os.Exit(1)
	}

	if len(hosts) == 0 {
		cli.PrintWarning("No se descubrieron hosts")
		return
	}

	table := cli.NewTable("Dirección IP", "Dirección MAC", "Fabricante", "Método")
	for _, h := range hosts {
		mac := h.MAC
		if mac == "" {
			mac = "N/A"
		}
		vendor := h.Vendor
		if vendor == "" {
			vendor = "Desconocido"
		}
		table.AddRow(h.IP, mac, vendor, h.Method)
	}
	table.Print()

	cli.PrintSuccess("Se descubrieron %d host(s)", len(hosts))

	path, err := report.ExportHostDiscovery(resultsDir, iface, hosts)
	if err != nil {
		logger.Error("Error al exportar reporte: %v", err)
	} else {
		cli.PrintSuccess("Reporte guardado: %s", path)
	}
}

// cmdScan executes port scanning from CLI flags.
func cmdScan(cmd *cli.Command) {
	cli.PrintSection("Escáner de Puertos Asíncrono")
	logger.Action("Comando: scan")

	target := cmd.GetFlag("target", "")
	if target == "" {
		cli.PrintError("Se requiere --target <ip/hostname>")
		cli.PrintInfo("Ejemplo: netaudit scan --target 192.168.1.1 --ports 1-1024")
		os.Exit(1)
	}

	portRange := cmd.GetFlag("ports", "")
	concurrency, _ := strconv.Atoi(cmd.GetFlag("concurrency", "500"))
	timeoutMs, _ := strconv.Atoi(cmd.GetFlag("timeout", "2000"))

	if concurrency <= 0 {
		concurrency = 500
	}
	if timeoutMs <= 0 {
		timeoutMs = 2000
	}

	cfg := scanner.ScanConfig{
		Target:      target,
		PortRange:   portRange,
		Timeout:     time.Duration(timeoutMs) * time.Millisecond,
		Concurrency: concurrency,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	cli.PrintInfo("Escaneando %s (concurrencia: %d, timeout: %dms)...", target, concurrency, timeoutMs)
	logger.Info("Escaneo: target=%s, rango=%s, concurrencia=%d", target, portRange, concurrency)
	fmt.Println()

	start := time.Now()
	results, err := scanner.ScanPorts(ctx, cfg)
	elapsed := time.Since(start)

	if err != nil {
		cli.PrintError("Escaneo fallido: %v", err)
		logger.Error("Escaneo fallido en %s: %v", target, err)
		os.Exit(1)
	}

	if len(results) == 0 {
		cli.PrintWarning("No se encontraron puertos abiertos en %s", target)
		return
	}

	table := cli.NewTable("Puerto", "Estado", "Servicio")
	for _, r := range results {
		svc := r.Service
		if svc == "" {
			svc = "desconocido"
		}
		table.AddRow(fmt.Sprintf("%d", r.Port), r.State, svc)
	}
	table.Print()

	cli.PrintSuccess("Se encontraron %d puerto(s) abierto(s) en %s", len(results), elapsed.Round(time.Millisecond))

	path, err := report.ExportPortScan(resultsDir, target, results)
	if err != nil {
		logger.Error("Error al exportar reporte: %v", err)
	} else {
		cli.PrintSuccess("Reporte guardado: %s", path)
	}
}

// cmdBanner executes banner grabbing from CLI flags.
func cmdBanner(cmd *cli.Command) {
	cli.PrintSection("Inspección de Servicios / Banner")
	logger.Action("Comando: banner")

	target := cmd.GetFlag("target", "")
	if target == "" {
		cli.PrintError("Se requiere --target <ip/hostname>")
		cli.PrintInfo("Ejemplo: netaudit banner --target 192.168.1.1")
		os.Exit(1)
	}

	timeoutMs, _ := strconv.Atoi(cmd.GetFlag("timeout", "5000"))
	if timeoutMs <= 0 {
		timeoutMs = 5000
	}
	timeout := time.Duration(timeoutMs) * time.Millisecond

	var results []*banner.Result

	// If specific port given, only probe that
	if cmd.HasFlag("port") {
		port, _ := strconv.Atoi(cmd.GetFlag("port", "0"))
		if port <= 0 || port > 65535 {
			cli.PrintError("Puerto inválido: %s", cmd.GetFlag("port", ""))
			os.Exit(1)
		}
		cli.PrintInfo("Sondeando puerto %d en %s...", port, target)
		result, err := banner.Grab(target, port, timeout)
		if err != nil {
			cli.PrintError("Sondeo fallido: %v", err)
			os.Exit(1)
		}
		results = append(results, result)
		displayBannerResult(result)
	} else {
		// Default: probe SSH (22) and FTP (21)
		cli.PrintInfo("Sondeando SSH (puerto 22)...")
		sshResult, err := banner.ProbeSSH(target, timeout)
		if err != nil {
			cli.PrintWarning("SSH: %v", err)
		} else {
			results = append(results, sshResult)
			displayBannerResult(sshResult)
		}

		cli.PrintInfo("Sondeando FTP (puerto 21)...")
		ftpResult, err := banner.ProbeFTP(target, timeout)
		if err != nil {
			cli.PrintWarning("FTP: %v", err)
		} else {
			results = append(results, ftpResult)
			displayBannerResult(ftpResult)
		}
	}

	if len(results) > 0 {
		path, err := report.ExportBannerGrab(resultsDir, target, results)
		if err != nil {
			logger.Error("Error al exportar reporte: %v", err)
		} else {
			cli.PrintSuccess("Reporte guardado: %s", path)
		}
	}
}

// cmdSockets executes local sockets listing from CLI.
func cmdSockets() {
	cli.PrintSection("Sockets Locales en Escucha")
	logger.Action("Comando: sockets")

	sockets, err := firewall.GetListeningSockets()
	if err != nil {
		cli.PrintError("Error al obtener sockets: %v", err)
		cli.PrintInfo("Puede requerir privilegios elevados (sudo)")
		os.Exit(1)
	}

	if len(sockets) == 0 {
		cli.PrintWarning("No se encontraron sockets en escucha")
		return
	}

	table := cli.NewTable("Protocolo", "Dirección", "Puerto", "PID", "Proceso")
	for _, s := range sockets {
		pidStr := fmt.Sprintf("%d", s.PID)
		if s.PID == 0 {
			pidStr = "-"
		}
		proc := s.Process
		if proc == "" {
			proc = "-"
		}
		table.AddRow(s.Protocol, s.Address, fmt.Sprintf("%d", s.Port), pidStr, proc)
	}
	table.Print()

	cli.PrintSuccess("Se encontraron %d socket(s) en escucha", len(sockets))

	path, err := report.ExportLocalSockets(resultsDir, sockets)
	if err != nil {
		logger.Error("Error al exportar reporte: %v", err)
	} else {
		cli.PrintSuccess("Reporte guardado: %s", path)
	}
}

// cmdFirewall executes firewall operations from CLI flags.
func cmdFirewall(cmd *cli.Command) {
	cli.PrintSection("Gestión de Reglas de Firewall")
	logger.Action("Comando: firewall")

	if err := scanner.CheckPrivileges(); err != nil {
		cli.PrintError("%v", err)
		os.Exit(1)
	}

	proto := cmd.GetFlag("proto", "tcp")
	var results []firewall.RuleResult

	if cmd.HasFlag("block") {
		port, _ := strconv.Atoi(cmd.GetFlag("block", "0"))
		if port <= 0 || port > 65535 {
			cli.PrintError("Puerto inválido para --block")
			os.Exit(1)
		}
		rule := firewall.Rule{Port: port, Protocol: proto, Action: "block", Dir: "in"}
		logger.Command("Firewall CLI: bloquear puerto %d/%s", port, proto)
		result, err := firewall.ApplyRule(rule)
		if err != nil {
			cli.PrintError("Fallo: %v", err)
			os.Exit(1)
		}
		if result.Success {
			cli.PrintSuccess("Puerto %d/%s bloqueado: %s", port, proto, result.Message)
			cli.PrintInfo("Comando ejecutado: %s", result.Command)
		} else {
			cli.PrintError("Fallo: %s", result.Message)
		}
		results = append(results, *result)

	} else if cmd.HasFlag("allow") {
		port, _ := strconv.Atoi(cmd.GetFlag("allow", "0"))
		if port <= 0 || port > 65535 {
			cli.PrintError("Puerto inválido para --allow")
			os.Exit(1)
		}
		rule := firewall.Rule{Port: port, Protocol: proto, Action: "allow", Dir: "in"}
		logger.Command("Firewall CLI: permitir puerto %d/%s", port, proto)
		result, err := firewall.ApplyRule(rule)
		if err != nil {
			cli.PrintError("Fallo: %v", err)
			os.Exit(1)
		}
		if result.Success {
			cli.PrintSuccess("Puerto %d/%s permitido: %s", port, proto, result.Message)
			cli.PrintInfo("Comando ejecutado: %s", result.Command)
		} else {
			cli.PrintError("Fallo: %s", result.Message)
		}
		results = append(results, *result)

	} else if cmd.HasFlag("remove") {
		port, _ := strconv.Atoi(cmd.GetFlag("remove", "0"))
		if port <= 0 || port > 65535 {
			cli.PrintError("Puerto inválido para --remove")
			os.Exit(1)
		}
		rule := firewall.Rule{Port: port, Protocol: proto, Action: "block", Dir: "in"}
		logger.Command("Firewall CLI: eliminar regla puerto %d/%s", port, proto)
		result, err := firewall.RemoveRule(rule)
		if err != nil {
			cli.PrintError("Fallo: %v", err)
			os.Exit(1)
		}
		if result.Success {
			cli.PrintSuccess("Regla eliminada para puerto %d/%s: %s", port, proto, result.Message)
		} else {
			cli.PrintError("Fallo: %s", result.Message)
		}
		results = append(results, *result)

	} else {
		cli.PrintError("Se requiere --block, --allow, o --remove <puerto>")
		cli.PrintInfo("Ejemplo: netaudit firewall --block 4444 --proto tcp")
		os.Exit(1)
	}

	if len(results) > 0 {
		path, err := report.ExportFirewallOps(resultsDir, results)
		if err != nil {
			logger.Error("Error al exportar reporte: %v", err)
		} else {
			cli.PrintSuccess("Reporte guardado: %s", path)
		}
	}
}

// cmdAudit executes a full audit from CLI flags.
func cmdAudit(cmd *cli.Command) {
	cli.PrintSection("Auditoría Completa de Red")
	logger.Action("Comando: audit")

	target := cmd.GetFlag("target", "")
	if target == "" {
		cli.PrintError("Se requiere --target <ip/hostname>")
		cli.PrintInfo("Ejemplo: netaudit audit --target 192.168.1.1")
		os.Exit(1)
	}

	cli.PrintInfo("Iniciando auditoría completa de %s...", target)
	logger.Info("Auditoría completa CLI para target: %s", target)
	fmt.Println()

	auditData := report.FullAuditData{Target: target}

	// Phase 1
	cli.PrintInfo("Fase 1: Descubrimiento de Hosts...")
	defaultIface, _ := scanner.GetDefaultInterface()
	if defaultIface != "" {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
		hosts, err := scanner.ARPScan(ctx, defaultIface, 800*time.Millisecond)
		cancel()
		if err == nil && len(hosts) > 0 {
			cli.PrintSuccess("Se descubrieron %d host(s)", len(hosts))
			auditData.Hosts = hosts
			auditData.Interface = defaultIface
		} else {
			cli.PrintWarning("Descubrimiento: %v", err)
		}
	}

	// Phase 2
	cli.PrintInfo("Fase 2: Escaneo de Puertos en %s...", target)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	ports, err := scanner.ScanPorts(ctx, scanner.ScanConfig{
		Target:      target,
		Timeout:     2 * time.Second,
		Concurrency: 500,
	})
	cancel()
	if err == nil && len(ports) > 0 {
		cli.PrintSuccess("Se encontraron %d puerto(s) abierto(s)", len(ports))
		auditData.Ports = ports

		table := cli.NewTable("Puerto", "Servicio")
		for _, p := range ports {
			svc := p.Service
			if svc == "" {
				svc = "desconocido"
			}
			table.AddRow(fmt.Sprintf("%d", p.Port), svc)
		}
		table.Print()
	} else {
		cli.PrintWarning("No se encontraron puertos abiertos")
	}

	// Phase 3
	cli.PrintInfo("Fase 3: Análisis de Banners...")
	var banners []*banner.Result
	for _, p := range ports {
		if p.Port == 22 || p.Port == 21 {
			result, err := banner.Grab(target, p.Port, 5*time.Second)
			if err == nil {
				banners = append(banners, result)
				status := "SEGURO"
				if !result.Secure {
					status = "INSEGURO"
				}
				cli.PrintInfo("  Puerto %d (%s): %s - %s", p.Port, result.Service, result.Banner, status)
			}
		}
	}
	auditData.Banners = banners

	// Phase 4
	cli.PrintInfo("Fase 4: Sockets Locales...")
	sockets, err := firewall.GetListeningSockets()
	if err == nil && len(sockets) > 0 {
		cli.PrintSuccess("Se encontraron %d socket(s) en escucha", len(sockets))
		auditData.Sockets = sockets
	}

	fmt.Println()
	cli.PrintSuccess("¡Auditoría completa finalizada!")

	path, err := report.ExportFullAudit(resultsDir, auditData)
	if err != nil {
		cli.PrintError("Error al exportar reporte: %v", err)
		os.Exit(1)
	}
	cli.PrintSuccess("Reporte de auditoría guardado: %s", path)
}

// runHostDiscovery performs ARP/ICMP host discovery on the local subnet.
func runHostDiscovery(menu *cli.Menu) {
	cli.PrintSection("Descubrimiento de Hosts (Barrido ARP/ICMP)")
	logger.Action("Iniciando descubrimiento de hosts")

	defaultIface, err := scanner.GetDefaultInterface()
	if err != nil {
		defaultIface = "eth0"
	}

	iface := menu.PromptDefault("Interfaz de red", defaultIface)
	timeoutStr := menu.PromptDefault("Timeout por host (ms)", "1000")
	timeoutMs, _ := strconv.Atoi(timeoutStr)
	if timeoutMs <= 0 {
		timeoutMs = 1000
	}

	timeout := time.Duration(timeoutMs) * time.Millisecond
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	cli.PrintInfo("Escaneando subred en interfaz %s (timeout: %dms)...", iface, timeoutMs)
	logger.Info("Barrido ARP en interfaz %s con timeout %dms", iface, timeoutMs)
	fmt.Println()

	hosts, err := scanner.ARPScan(ctx, iface, timeout)
	if err != nil {
		cli.PrintError("Escaneo fallido: %v", err)
		logger.Error("Barrido ARP fallido: %v", err)
		return
	}

	if len(hosts) == 0 {
		cli.PrintWarning("No se descubrieron hosts")
		logger.Warn("No se descubrieron hosts en %s", iface)
		return
	}

	// Display results
	table := cli.NewTable("Dirección IP", "Dirección MAC", "Fabricante", "Método")
	for _, h := range hosts {
		mac := h.MAC
		if mac == "" {
			mac = "N/A"
		}
		vendor := h.Vendor
		if vendor == "" {
			vendor = "Desconocido"
		}
		table.AddRow(h.IP, mac, vendor, h.Method)
	}
	table.Print()

	cli.PrintSuccess("Se descubrieron %d host(s)", len(hosts))
	logger.Info("Descubrimiento completado: %d host(s) encontrados", len(hosts))

	// Store session data
	sessionData.hosts = hosts
	sessionData.iface = iface

	// Auto-export report
	path, err := report.ExportHostDiscovery(resultsDir, iface, hosts)
	if err != nil {
		logger.Error("Error al exportar reporte de hosts: %v", err)
	} else {
		cli.PrintSuccess("Reporte guardado: %s", path)
		logger.Info("Reporte de hosts exportado: %s", path)
	}
}

// runPortScan performs an async TCP port scan.
func runPortScan(menu *cli.Menu) {
	cli.PrintSection("Escáner de Puertos Asíncrono")
	logger.Action("Iniciando escaneo de puertos")

	target := menu.Prompt("IP/hostname objetivo")
	if target == "" {
		cli.PrintError("El objetivo no puede estar vacío")
		return
	}

	portRange := menu.PromptDefault("Rango de puertos (ej: 1-1024, 22,80,443)", "por defecto")
	if portRange == "por defecto" {
		portRange = ""
	}

	concurrencyStr := menu.PromptDefault("Concurrencia (goroutines)", "500")
	concurrency, _ := strconv.Atoi(concurrencyStr)
	if concurrency <= 0 {
		concurrency = 500
	}

	timeoutStr := menu.PromptDefault("Timeout por puerto (ms)", "2000")
	timeoutMs, _ := strconv.Atoi(timeoutStr)
	if timeoutMs <= 0 {
		timeoutMs = 2000
	}

	cfg := scanner.ScanConfig{
		Target:      target,
		PortRange:   portRange,
		Timeout:     time.Duration(timeoutMs) * time.Millisecond,
		Concurrency: concurrency,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	cli.PrintInfo("Escaneando %s (concurrencia: %d, timeout: %dms)...", target, concurrency, timeoutMs)
	logger.Info("Escaneo de puertos: target=%s, rango=%s, concurrencia=%d", target, portRange, concurrency)
	fmt.Println()

	start := time.Now()
	results, err := scanner.ScanPorts(ctx, cfg)
	elapsed := time.Since(start)

	if err != nil {
		cli.PrintError("Escaneo de puertos fallido: %v", err)
		logger.Error("Escaneo de puertos fallido en %s: %v", target, err)
		return
	}

	if len(results) == 0 {
		cli.PrintWarning("No se encontraron puertos abiertos en %s", target)
		logger.Info("No se encontraron puertos abiertos en %s", target)
		return
	}

	table := cli.NewTable("Puerto", "Estado", "Servicio")
	for _, r := range results {
		svc := r.Service
		if svc == "" {
			svc = "desconocido"
		}
		table.AddRow(fmt.Sprintf("%d", r.Port), r.State, svc)
	}
	table.Print()

	cli.PrintSuccess("Se encontraron %d puerto(s) abierto(s) en %s", len(results), elapsed.Round(time.Millisecond))
	logger.Info("Escaneo completado: %d puertos abiertos en %s (%s)", len(results), target, elapsed.Round(time.Millisecond))

	// Store session data
	sessionData.ports = results
	sessionData.target = target

	// Auto-export report
	path, err := report.ExportPortScan(resultsDir, target, results)
	if err != nil {
		logger.Error("Error al exportar reporte de puertos: %v", err)
	} else {
		cli.PrintSuccess("Reporte guardado: %s", path)
		logger.Info("Reporte de puertos exportado: %s", path)
	}
}

// runBannerGrab performs banner grabbing on SSH/FTP ports.
func runBannerGrab(menu *cli.Menu) {
	cli.PrintSection("Inspección de Servicios / Banner (Análisis SSH/FTP)")
	logger.Action("Iniciando inspección de banners")

	target := menu.Prompt("IP/hostname objetivo")
	if target == "" {
		cli.PrintError("El objetivo no puede estar vacío")
		return
	}

	timeoutStr := menu.PromptDefault("Timeout (ms)", "5000")
	timeoutMs, _ := strconv.Atoi(timeoutStr)
	if timeoutMs <= 0 {
		timeoutMs = 5000
	}
	timeout := time.Duration(timeoutMs) * time.Millisecond

	var results []*banner.Result

	// Probe SSH (port 22)
	cli.PrintInfo("Sondeando SSH (puerto 22)...")
	logger.Info("Banner grab SSH en %s:22", target)
	sshResult, err := banner.ProbeSSH(target, timeout)
	if err != nil {
		cli.PrintWarning("Sondeo SSH fallido: %v", err)
		logger.Warn("Sondeo SSH fallido en %s: %v", target, err)
	} else {
		results = append(results, sshResult)
		displayBannerResult(sshResult)
	}

	// Probe FTP (port 21)
	cli.PrintInfo("Sondeando FTP (puerto 21)...")
	logger.Info("Banner grab FTP en %s:21", target)
	ftpResult, err := banner.ProbeFTP(target, timeout)
	if err != nil {
		cli.PrintWarning("Sondeo FTP fallido: %v", err)
		logger.Warn("Sondeo FTP fallido en %s: %v", target, err)
	} else {
		results = append(results, ftpResult)
		displayBannerResult(ftpResult)
	}

	// Ask if user wants to probe a custom port
	if menu.Confirm("¿Sondear un puerto personalizado?") {
		portStr := menu.Prompt("Número de puerto")
		port, _ := strconv.Atoi(portStr)
		if port > 0 && port <= 65535 {
			cli.PrintInfo("Sondeando puerto %d...", port)
			logger.Info("Banner grab personalizado en %s:%d", target, port)
			customResult, err := banner.Grab(target, port, timeout)
			if err != nil {
				cli.PrintWarning("Sondeo fallido: %v", err)
				logger.Warn("Sondeo fallido en %s:%d: %v", target, port, err)
			} else {
				results = append(results, customResult)
				displayBannerResult(customResult)
			}
		}
	}

	if len(results) > 0 {
		sessionData.banners = results
		sessionData.target = target
		logger.Info("Inspección completada: %d servicio(s) analizados", len(results))

		// Auto-export report
		path, err := report.ExportBannerGrab(resultsDir, target, results)
		if err != nil {
			logger.Error("Error al exportar reporte de banners: %v", err)
		} else {
			cli.PrintSuccess("Reporte guardado: %s", path)
			logger.Info("Reporte de banners exportado: %s", path)
		}
	}
}

// displayBannerResult displays a single banner result with security info.
func displayBannerResult(r *banner.Result) {
	fmt.Println()
	table := cli.NewTable("Campo", "Valor")
	table.AddRow("Servicio", r.Service)
	table.AddRow("Puerto", fmt.Sprintf("%d", r.Port))
	table.AddRow("Banner", r.Banner)
	if r.Version != "" {
		table.AddRow("Versión", r.Version)
	}
	if r.Details != "" {
		table.AddRow("Detalles", r.Details)
	}
	secureStatus := cli.Green + "SEGURO" + cli.Reset
	if !r.Secure {
		secureStatus = cli.Red + "INSEGURO" + cli.Reset
	}
	table.AddRow("Seguridad", secureStatus)
	table.Print()
}

// runLocalSockets displays all listening local sockets.
func runLocalSockets() {
	cli.PrintSection("Sockets Locales en Escucha")
	logger.Action("Consultando sockets locales en escucha")

	sockets, err := firewall.GetListeningSockets()
	if err != nil {
		cli.PrintError("Error al obtener sockets en escucha: %v", err)
		cli.PrintInfo("Esto puede requerir privilegios elevados (sudo)")
		logger.Error("Fallo al obtener sockets: %v", err)
		return
	}

	if len(sockets) == 0 {
		cli.PrintWarning("No se encontraron sockets en escucha")
		logger.Info("No se encontraron sockets en escucha")
		return
	}

	table := cli.NewTable("Protocolo", "Dirección", "Puerto", "PID", "Proceso")
	for _, s := range sockets {
		pidStr := fmt.Sprintf("%d", s.PID)
		if s.PID == 0 {
			pidStr = "-"
		}
		process := s.Process
		if process == "" {
			process = "-"
		}
		table.AddRow(s.Protocol, s.Address, fmt.Sprintf("%d", s.Port), pidStr, process)
	}
	table.Print()

	cli.PrintSuccess("Se encontraron %d socket(s) en escucha", len(sockets))
	logger.Info("Sockets en escucha encontrados: %d", len(sockets))

	// Store session data
	sessionData.sockets = sockets

	// Auto-export report
	path, err := report.ExportLocalSockets(resultsDir, sockets)
	if err != nil {
		logger.Error("Error al exportar reporte de sockets: %v", err)
	} else {
		cli.PrintSuccess("Reporte guardado: %s", path)
		logger.Info("Reporte de sockets exportado: %s", path)
	}
}

// runFirewallManagement handles firewall rule management.
func runFirewallManagement(menu *cli.Menu) {
	cli.PrintSection("Gestión de Reglas de Firewall")
	logger.Action("Accediendo a gestión de firewall")

	if err := scanner.CheckPrivileges(); err != nil {
		cli.PrintError("%v", err)
		cli.PrintInfo("La gestión de firewall requiere privilegios de root/administrador")
		logger.Error("Privilegios insuficientes para gestión de firewall: %v", err)
		return
	}

	for {
		choice := menu.ShowFirewallMenu()
		logger.Action("Submenú firewall - opción: %s", choice)

		switch choice {
		case "1":
			portStr := menu.Prompt("Puerto a bloquear")
			port, _ := strconv.Atoi(portStr)
			if port <= 0 || port > 65535 {
				cli.PrintError("Número de puerto inválido")
				continue
			}
			proto := menu.PromptDefault("Protocolo", "tcp")
			if !menu.Confirm(fmt.Sprintf("¿Bloquear puerto %d/%s entrante?", port, proto)) {
				continue
			}
			rule := firewall.Rule{Port: port, Protocol: proto, Action: "block", Dir: "in"}
			logger.Command("Firewall: bloquear puerto %d/%s entrante", port, proto)
			result, err := firewall.ApplyRule(rule)
			if err != nil {
				cli.PrintError("Fallo: %v", err)
				logger.Error("Fallo al bloquear puerto %d: %v", port, err)
			} else if result.Success {
				cli.PrintSuccess("Puerto %d bloqueado: %s", port, result.Message)
				cli.PrintInfo("Comando: %s", result.Command)
				logger.Info("Puerto %d/%s bloqueado. Cmd: %s", port, proto, result.Command)
				sessionData.fwOps = append(sessionData.fwOps, *result)
			} else {
				cli.PrintError("Fallo: %s", result.Message)
				logger.Error("Fallo al bloquear puerto %d: %s", port, result.Message)
			}

		case "2":
			portStr := menu.Prompt("Puerto a permitir")
			port, _ := strconv.Atoi(portStr)
			if port <= 0 || port > 65535 {
				cli.PrintError("Número de puerto inválido")
				continue
			}
			proto := menu.PromptDefault("Protocolo", "tcp")
			rule := firewall.Rule{Port: port, Protocol: proto, Action: "allow", Dir: "in"}
			logger.Command("Firewall: permitir puerto %d/%s entrante", port, proto)
			result, err := firewall.ApplyRule(rule)
			if err != nil {
				cli.PrintError("Fallo: %v", err)
				logger.Error("Fallo al permitir puerto %d: %v", port, err)
			} else if result.Success {
				cli.PrintSuccess("Puerto %d permitido: %s", port, result.Message)
				cli.PrintInfo("Comando: %s", result.Command)
				logger.Info("Puerto %d/%s permitido. Cmd: %s", port, proto, result.Command)
				sessionData.fwOps = append(sessionData.fwOps, *result)
			} else {
				cli.PrintError("Fallo: %s", result.Message)
				logger.Error("Fallo al permitir puerto %d: %s", port, result.Message)
			}

		case "3":
			portStr := menu.Prompt("Puerto de la regla a eliminar")
			port, _ := strconv.Atoi(portStr)
			if port <= 0 || port > 65535 {
				cli.PrintError("Número de puerto inválido")
				continue
			}
			proto := menu.PromptDefault("Protocolo", "tcp")
			action := menu.PromptDefault("Acción a eliminar (allow/block)", "block")
			rule := firewall.Rule{Port: port, Protocol: proto, Action: action, Dir: "in"}
			logger.Command("Firewall: eliminar regla %s puerto %d/%s", action, port, proto)
			result, err := firewall.RemoveRule(rule)
			if err != nil {
				cli.PrintError("Fallo: %v", err)
				logger.Error("Fallo al eliminar regla puerto %d: %v", port, err)
			} else if result.Success {
				cli.PrintSuccess("Regla eliminada: %s", result.Message)
				logger.Info("Regla eliminada para puerto %d/%s", port, proto)
				sessionData.fwOps = append(sessionData.fwOps, *result)
			} else {
				cli.PrintError("Fallo: %s", result.Message)
				logger.Error("Fallo al eliminar regla puerto %d: %s", port, result.Message)
			}

		case "0", "":
			// Export firewall ops if any
			if len(sessionData.fwOps) > 0 {
				path, err := report.ExportFirewallOps(resultsDir, sessionData.fwOps)
				if err != nil {
					logger.Error("Error al exportar reporte de firewall: %v", err)
				} else {
					cli.PrintSuccess("Reporte de firewall guardado: %s", path)
					logger.Info("Reporte de firewall exportado: %s", path)
				}
			}
			return
		default:
			cli.PrintError("Opción inválida")
		}
	}
}

// runFullAudit performs all scans and generates a complete report.
func runFullAudit(menu *cli.Menu) {
	cli.PrintSection("Auditoría Completa de Red")
	logger.Action("Iniciando auditoría completa")

	target := menu.Prompt("IP/hostname objetivo para escaneo de puertos")
	if target == "" {
		cli.PrintError("El objetivo no puede estar vacío")
		return
	}

	cli.PrintInfo("Iniciando auditoría completa de %s...", target)
	logger.Info("Auditoría completa iniciada para target: %s", target)
	fmt.Println()

	auditData := report.FullAuditData{Target: target}

	// Phase 1: Host Discovery
	cli.PrintInfo("Fase 1: Descubrimiento de Hosts...")
	logger.Info("Fase 1: Descubrimiento de hosts")
	defaultIface, _ := scanner.GetDefaultInterface()
	if defaultIface != "" {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
		hosts, err := scanner.ARPScan(ctx, defaultIface, 800*time.Millisecond)
		cancel()
		if err == nil && len(hosts) > 0 {
			cli.PrintSuccess("Se descubrieron %d host(s)", len(hosts))
			logger.Info("Fase 1: %d hosts descubiertos", len(hosts))
			auditData.Hosts = hosts
			auditData.Interface = defaultIface
		} else {
			cli.PrintWarning("Descubrimiento de hosts: %v", err)
			logger.Warn("Fase 1 con advertencia: %v", err)
		}
	}

	// Phase 2: Port Scan
	cli.PrintInfo("Fase 2: Escaneo de Puertos en %s...", target)
	logger.Info("Fase 2: Escaneo de puertos en %s", target)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	ports, err := scanner.ScanPorts(ctx, scanner.ScanConfig{
		Target:      target,
		Timeout:     2 * time.Second,
		Concurrency: 500,
	})
	cancel()
	if err == nil && len(ports) > 0 {
		cli.PrintSuccess("Se encontraron %d puerto(s) abierto(s)", len(ports))
		logger.Info("Fase 2: %d puertos abiertos", len(ports))
		auditData.Ports = ports

		table := cli.NewTable("Puerto", "Servicio")
		for _, p := range ports {
			svc := p.Service
			if svc == "" {
				svc = "desconocido"
			}
			table.AddRow(fmt.Sprintf("%d", p.Port), svc)
		}
		table.Print()
	} else {
		cli.PrintWarning("No se encontraron puertos abiertos")
		logger.Info("Fase 2: No se encontraron puertos abiertos")
	}

	// Phase 3: Banner Grab
	cli.PrintInfo("Fase 3: Análisis de Banners...")
	logger.Info("Fase 3: Análisis de banners")
	var banners []*banner.Result
	for _, p := range ports {
		if p.Port == 22 || p.Port == 21 {
			result, err := banner.Grab(target, p.Port, 5*time.Second)
			if err == nil {
				banners = append(banners, result)
				status := "SEGURO"
				if !result.Secure {
					status = "INSEGURO"
				}
				cli.PrintInfo("  Puerto %d (%s): %s - %s", p.Port, result.Service, result.Banner, status)
				logger.Info("Banner puerto %d: %s [%s]", p.Port, result.Banner, status)
			}
		}
	}
	auditData.Banners = banners

	// Phase 4: Local Sockets
	cli.PrintInfo("Fase 4: Sockets Locales en Escucha...")
	logger.Info("Fase 4: Detección de sockets locales")
	sockets, err := firewall.GetListeningSockets()
	if err == nil && len(sockets) > 0 {
		cli.PrintSuccess("Se encontraron %d socket(s) en escucha", len(sockets))
		logger.Info("Fase 4: %d sockets en escucha", len(sockets))
		auditData.Sockets = sockets
	}

	fmt.Println()
	cli.PrintSuccess("¡Auditoría completa finalizada!")
	logger.Info("Auditoría completa finalizada para %s", target)

	// Export full audit report
	path, err := report.ExportFullAudit(resultsDir, auditData)
	if err != nil {
		cli.PrintError("Error al exportar reporte: %v", err)
		logger.Error("Error al exportar reporte de auditoría completa: %v", err)
	} else {
		cli.PrintSuccess("Reporte de auditoría guardado: %s", path)
		logger.Info("Reporte de auditoría completa exportado: %s", path)
	}
}

// exportReport allows manual export of accumulated session data.
func exportReport(menu *cli.Menu) {
	cli.PrintSection("Exportar Reporte de Auditoría")
	logger.Action("Exportación manual de reporte")

	fmt.Println("  Datos disponibles en la sesión actual:")
	fmt.Println()
	if len(sessionData.hosts) > 0 {
		fmt.Printf("    • Hosts descubiertos: %d\n", len(sessionData.hosts))
	}
	if len(sessionData.ports) > 0 {
		fmt.Printf("    • Puertos escaneados: %d abiertos\n", len(sessionData.ports))
	}
	if len(sessionData.banners) > 0 {
		fmt.Printf("    • Servicios analizados: %d\n", len(sessionData.banners))
	}
	if len(sessionData.sockets) > 0 {
		fmt.Printf("    • Sockets locales: %d\n", len(sessionData.sockets))
	}
	if len(sessionData.fwOps) > 0 {
		fmt.Printf("    • Operaciones firewall: %d\n", len(sessionData.fwOps))
	}
	fmt.Println()

	hasData := len(sessionData.hosts) > 0 || len(sessionData.ports) > 0 ||
		len(sessionData.banners) > 0 || len(sessionData.sockets) > 0

	if !hasData {
		cli.PrintWarning("No hay datos para exportar. Ejecute primero algún escaneo.")
		return
	}

	// Export as full combined report
	if menu.Confirm("¿Exportar como reporte combinado de auditoría?") {
		auditData := report.FullAuditData{
			Target:    sessionData.target,
			Interface: sessionData.iface,
			Hosts:     sessionData.hosts,
			Ports:     sessionData.ports,
			Banners:   sessionData.banners,
			Sockets:   sessionData.sockets,
		}
		path, err := report.ExportFullAudit(resultsDir, auditData)
		if err != nil {
			cli.PrintError("Exportación fallida: %v", err)
			logger.Error("Exportación manual fallida: %v", err)
		} else {
			cli.PrintSuccess("Reporte exportado en: %s", path)
			logger.Info("Reporte manual exportado: %s", path)
		}
	}
}
