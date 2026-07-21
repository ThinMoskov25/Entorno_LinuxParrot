package cli

import (
	"fmt"
	"os"
	"strings"
)

// Command represents a parsed CLI command with its flags.
type Command struct {
	Name  string
	Flags map[string]string
}

// Supported commands
const (
	CmdDiscover = "discover"
	CmdScan     = "scan"
	CmdBanner   = "banner"
	CmdSockets  = "sockets"
	CmdFirewall = "firewall"
	CmdAudit    = "audit"
	CmdHelp     = "help"
)

// ParseArgs parses os.Args and returns a Command if CLI mode is detected.
// Returns nil if no subcommand is provided (interactive mode).
func ParseArgs(args []string) *Command {
	if len(args) < 2 {
		return nil
	}

	subcmd := strings.ToLower(args[1])

	// If it doesn't match a known command, assume interactive mode
	if !isValidCommand(subcmd) {
		return nil
	}

	cmd := &Command{
		Name:  subcmd,
		Flags: make(map[string]string),
	}

	// Parse --key value or --key=value flags
	for i := 2; i < len(args); i++ {
		arg := args[i]
		if !strings.HasPrefix(arg, "--") && !strings.HasPrefix(arg, "-") {
			continue
		}

		// Strip leading dashes
		key := strings.TrimLeft(arg, "-")

		// Handle --key=value
		if idx := strings.Index(key, "="); idx != -1 {
			cmd.Flags[key[:idx]] = key[idx+1:]
			continue
		}

		// Handle --key value
		if i+1 < len(args) && !strings.HasPrefix(args[i+1], "-") {
			cmd.Flags[key] = args[i+1]
			i++
		} else {
			// Flag without value (boolean flag)
			cmd.Flags[key] = "true"
		}
	}

	return cmd
}

// GetFlag returns the value of a flag, or the default if not set.
func (c *Command) GetFlag(name, defaultVal string) string {
	if val, ok := c.Flags[name]; ok {
		return val
	}
	return defaultVal
}

// HasFlag checks if a flag is present.
func (c *Command) HasFlag(name string) bool {
	_, ok := c.Flags[name]
	return ok
}

// isValidCommand checks if a string is a recognized subcommand.
func isValidCommand(cmd string) bool {
	switch cmd {
	case CmdDiscover, CmdScan, CmdBanner, CmdSockets, CmdFirewall, CmdAudit, CmdHelp:
		return true
	}
	return false
}

// PrintUsage prints the CLI usage help.
func PrintUsage() {
	usage := `
` + Bold + Cyan + `USO:` + Reset + `
  netaudit [comando] [flags]

  Sin argumentos se ejecuta en modo interactivo (menú).

` + Bold + Cyan + `COMANDOS DISPONIBLES:` + Reset + `

  ` + Green + `discover` + Reset + `    Descubrir hosts en la red local (ARP/ICMP)
  ` + Green + `scan` + Reset + `        Escanear puertos de un objetivo
  ` + Green + `banner` + Reset + `      Inspeccionar servicios SSH/FTP (banner grabbing)
  ` + Green + `sockets` + Reset + `     Listar sockets locales en escucha
  ` + Green + `firewall` + Reset + `    Gestionar reglas de firewall
  ` + Green + `audit` + Reset + `       Ejecutar auditoría completa
  ` + Green + `help` + Reset + `        Mostrar esta ayuda

` + Bold + Cyan + `FLAGS POR COMANDO:` + Reset + `

  ` + Yellow + `discover:` + Reset + `
    --iface <nombre>      Interfaz de red (default: auto-detectada)
    --timeout <ms>        Timeout por host en ms (default: 1000)

  ` + Yellow + `scan:` + Reset + `
    --target <ip/host>    IP o hostname objetivo (requerido)
    --ports <rango>       Rango de puertos, ej: 1-1024,8080 (default: comunes)
    --concurrency <n>     Goroutines simultáneas (default: 500)
    --timeout <ms>        Timeout por puerto en ms (default: 2000)

  ` + Yellow + `banner:` + Reset + `
    --target <ip/host>    IP o hostname objetivo (requerido)
    --port <n>            Puerto específico (default: 21,22)
    --timeout <ms>        Timeout en ms (default: 5000)

  ` + Yellow + `sockets:` + Reset + `
    (sin flags adicionales)

  ` + Yellow + `firewall:` + Reset + `
    --block <puerto>      Bloquear un puerto (entrante)
    --allow <puerto>      Permitir un puerto (entrante)
    --remove <puerto>     Eliminar regla de un puerto
    --proto <tcp|udp>     Protocolo (default: tcp)

  ` + Yellow + `audit:` + Reset + `
    --target <ip/host>    IP o hostname objetivo (requerido)

` + Bold + Cyan + `EJEMPLOS:` + Reset + `

  sudo ./netaudit discover --iface eth0
  sudo ./netaudit scan --target 192.168.1.1 --ports 1-1024
  sudo ./netaudit scan --target 10.0.0.1 --ports 22,80,443 --timeout 3000
  sudo ./netaudit banner --target 192.168.1.1
  sudo ./netaudit banner --target 192.168.1.1 --port 8080
  sudo ./netaudit sockets
  sudo ./netaudit firewall --block 4444
  sudo ./netaudit firewall --allow 80 --proto tcp
  sudo ./netaudit firewall --remove 4444
  sudo ./netaudit audit --target 192.168.1.0/24

`
	fmt.Fprint(os.Stdout, usage)
}
