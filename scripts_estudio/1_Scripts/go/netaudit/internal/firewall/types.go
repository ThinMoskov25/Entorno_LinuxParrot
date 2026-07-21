package firewall

// ListenSocket represents a local socket in LISTEN state.
type ListenSocket struct {
	Protocol string `json:"protocol"` // "tcp" or "udp"
	Address  string `json:"address"`
	Port     int    `json:"port"`
	PID      int    `json:"pid"`
	Process  string `json:"process"`
}

// Rule represents a firewall rule to apply.
type Rule struct {
	Port     int    `json:"port"`
	Protocol string `json:"protocol"` // "tcp", "udp", or "both"
	Action   string `json:"action"`   // "allow", "deny", "block"
	Dir      string `json:"direction"` // "in", "out", "both"
}

// RuleResult holds the outcome of a firewall rule operation.
type RuleResult struct {
	Success bool   `json:"success"`
	Rule    Rule   `json:"rule"`
	Message string `json:"message"`
	Command string `json:"command_executed"`
}
