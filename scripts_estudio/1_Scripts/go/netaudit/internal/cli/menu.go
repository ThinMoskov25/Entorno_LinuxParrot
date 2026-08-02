package cli

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// Menu represents the interactive CLI menu.
type Menu struct {
	reader *bufio.Reader
}

// NewMenu creates a new interactive menu.
func NewMenu() *Menu {
	return &Menu{
		reader: bufio.NewReader(os.Stdin),
	}
}

// ShowMainMenu displays the main menu and returns the user's choice.
func (m *Menu) ShowMainMenu() string {
	fmt.Println()
	fmt.Printf("%s%s╔══════════════════════════════════════════════════════╗%s\n", Bold, Cyan, Reset)
	fmt.Printf("%s%s║              MENÚ PRINCIPAL                          ║%s\n", Bold, Cyan, Reset)
	fmt.Printf("%s%s╠══════════════════════════════════════════════════════╣%s\n", Bold, Cyan, Reset)
	fmt.Printf("%s%s║%s  1. %sDescubrir Hosts%s (Barrido ARP/ICMP)              %s║%s\n", Bold, Cyan, Reset, Green, Reset, Cyan, Reset)
	fmt.Printf("%s%s║%s  2. %sEscanear Puertos%s (Escáner Asíncrono)            %s║%s\n", Bold, Cyan, Reset, Green, Reset, Cyan, Reset)
	fmt.Printf("%s%s║%s  3. %sInspeccionar Servicios / Banner%s (Análisis SSH/FTP)%s║%s\n", Bold, Cyan, Reset, Green, Reset, Cyan, Reset)
	fmt.Printf("%s%s║%s  4. %sSockets Locales%s (Puertos en Escucha)             %s║%s\n", Bold, Cyan, Reset, Yellow, Reset, Cyan, Reset)
	fmt.Printf("%s%s║%s  5. %sReglas de Firewall%s (Gestionar Puertos)           %s║%s\n", Bold, Cyan, Reset, Yellow, Reset, Cyan, Reset)
	fmt.Printf("%s%s║%s  6. %sAuditoría Completa%s (Escaneo Total + Reporte)     %s║%s\n", Bold, Cyan, Reset, Magenta, Reset, Cyan, Reset)
	fmt.Printf("%s%s║%s  7. %sExportar Reporte%s (JSON)                          %s║%s\n", Bold, Cyan, Reset, Blue, Reset, Cyan, Reset)
	fmt.Printf("%s%s║%s  0. %sSalir%s                                            %s║%s\n", Bold, Cyan, Reset, Red, Reset, Cyan, Reset)
	fmt.Printf("%s%s╚══════════════════════════════════════════════════════╝%s\n", Bold, Cyan, Reset)
	fmt.Println()

	return m.Prompt("Seleccione una opción")
}

// ShowFirewallMenu displays the firewall management submenu.
func (m *Menu) ShowFirewallMenu() string {
	fmt.Println()
	fmt.Printf("%s%s── Gestión de Firewall ──%s\n", Bold, Yellow, Reset)
	fmt.Println("  1. Bloquear un puerto (denegar entrante)")
	fmt.Println("  2. Permitir un puerto (habilitar entrante)")
	fmt.Println("  3. Eliminar una regla")
	fmt.Println("  0. Volver al menú principal")
	fmt.Println()

	return m.Prompt("Seleccione una opción")
}

// Prompt displays a prompt and reads user input.
func (m *Menu) Prompt(label string) string {
	fmt.Printf("%s%s➜ %s:%s ", Bold, Green, label, Reset)
	input, _ := m.reader.ReadString('\n')
	return strings.TrimSpace(input)
}

// PromptDefault displays a prompt with a default value.
func (m *Menu) PromptDefault(label, defaultVal string) string {
	fmt.Printf("%s%s➜ %s%s [%s]: ", Bold, Green, label, Reset, defaultVal)
	input, _ := m.reader.ReadString('\n')
	input = strings.TrimSpace(input)
	if input == "" {
		return defaultVal
	}
	return input
}

// Confirm asks for a yes/no confirmation.
func (m *Menu) Confirm(question string) bool {
	fmt.Printf("%s%s? %s%s (s/N): ", Bold, Yellow, question, Reset)
	input, _ := m.reader.ReadString('\n')
	input = strings.TrimSpace(strings.ToLower(input))
	return input == "s" || input == "si" || input == "sí" || input == "y" || input == "yes"
}
