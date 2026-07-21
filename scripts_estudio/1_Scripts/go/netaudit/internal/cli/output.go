package cli

import (
	"fmt"
	"strings"
)

// Colors for terminal output.
const (
	Reset   = "\033[0m"
	Red     = "\033[31m"
	Green   = "\033[32m"
	Yellow  = "\033[33m"
	Blue    = "\033[34m"
	Magenta = "\033[35m"
	Cyan    = "\033[36m"
	White   = "\033[37m"
	Bold    = "\033[1m"
)

// PrintBanner prints the application banner/logo.
func PrintBanner() {
	banner := `
` + Cyan + Bold + `
 ███╗   ██╗███████╗████████╗ █████╗ ██╗   ██╗██████╗ ██╗████████╗
 ████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔══██╗██║╚══██╔══╝
 ██╔██╗ ██║█████╗     ██║   ███████║██║   ██║██║  ██║██║   ██║   
 ██║╚██╗██║██╔══╝     ██║   ██╔══██║██║   ██║██║  ██║██║   ██║   
 ██║ ╚████║███████╗   ██║   ██║  ██║╚██████╔╝██████╔╝██║   ██║   
 ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝   ╚═╝   
` + Reset + `
` + Yellow + ` Network Audit & Security Tool v1.0 by Moskov - SrBalduR` + Reset + `
` + White + ` ─────────────────────────────────────────────────────────────────` + Reset + `
`
	fmt.Println(banner)
}

// PrintSection prints a section header.
func PrintSection(title string) {
	fmt.Printf("\n%s%s[*] %s%s\n", Bold, Cyan, title, Reset)
	fmt.Printf("%s%s%s\n", Cyan, strings.Repeat("─", len(title)+4), Reset)
}

// PrintSuccess prints a success message.
func PrintSuccess(format string, args ...interface{}) {
	msg := fmt.Sprintf(format, args...)
	fmt.Printf("%s[✓]%s %s\n", Green, Reset, msg)
}

// PrintWarning prints a warning message.
func PrintWarning(format string, args ...interface{}) {
	msg := fmt.Sprintf(format, args...)
	fmt.Printf("%s[!]%s %s\n", Yellow, Reset, msg)
}

// PrintError prints an error message.
func PrintError(format string, args ...interface{}) {
	msg := fmt.Sprintf(format, args...)
	fmt.Printf("%s[✗]%s %s\n", Red, Reset, msg)
}

// PrintInfo prints an informational message.
func PrintInfo(format string, args ...interface{}) {
	msg := fmt.Sprintf(format, args...)
	fmt.Printf("%s[i]%s %s\n", Blue, Reset, msg)
}
