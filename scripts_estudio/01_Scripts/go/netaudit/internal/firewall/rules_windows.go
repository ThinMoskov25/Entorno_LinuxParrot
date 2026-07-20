//go:build windows

package firewall

import (
	"fmt"
	"os/exec"
	"strings"
)

// ApplyRule applies a firewall rule using netsh advfirewall on Windows.
func ApplyRule(rule Rule) (*RuleResult, error) {
	return applyNetshRule(rule)
}

// RemoveRule removes a firewall rule on Windows.
func RemoveRule(rule Rule) (*RuleResult, error) {
	return removeNetshRule(rule)
}

// applyNetshRule creates a Windows Firewall rule using netsh.
func applyNetshRule(rule Rule) (*RuleResult, error) {
	action := mapActionToNetsh(rule.Action)
	dir := mapDirToNetsh(rule.Dir)
	proto := rule.Protocol
	if proto == "both" || proto == "" {
		proto = "tcp"
	}

	ruleName := fmt.Sprintf("NetAudit_%s_%d_%s", action, rule.Port, proto)

	args := []string{
		"advfirewall", "firewall", "add", "rule",
		fmt.Sprintf("name=%s", ruleName),
		fmt.Sprintf("dir=%s", dir),
		fmt.Sprintf("action=%s", action),
		fmt.Sprintf("protocol=%s", proto),
		fmt.Sprintf("localport=%d", rule.Port),
	}

	cmd := exec.Command("netsh", args...)
	cmdStr := "netsh " + strings.Join(args, " ")

	out, err := cmd.CombinedOutput()
	result := &RuleResult{
		Rule:    rule,
		Command: cmdStr,
	}

	if err != nil {
		result.Success = false
		result.Message = fmt.Sprintf("netsh failed: %s - %s", err.Error(), strings.TrimSpace(string(out)))
		return result, nil
	}

	result.Success = true
	result.Message = strings.TrimSpace(string(out))
	return result, nil
}

// removeNetshRule removes a Windows Firewall rule.
func removeNetshRule(rule Rule) (*RuleResult, error) {
	action := mapActionToNetsh(rule.Action)
	proto := rule.Protocol
	if proto == "both" || proto == "" {
		proto = "tcp"
	}

	ruleName := fmt.Sprintf("NetAudit_%s_%d_%s", action, rule.Port, proto)

	args := []string{
		"advfirewall", "firewall", "delete", "rule",
		fmt.Sprintf("name=%s", ruleName),
	}

	cmd := exec.Command("netsh", args...)
	cmdStr := "netsh " + strings.Join(args, " ")

	out, err := cmd.CombinedOutput()
	result := &RuleResult{
		Rule:    rule,
		Command: cmdStr,
	}

	if err != nil {
		result.Success = false
		result.Message = fmt.Sprintf("netsh delete failed: %s - %s", err.Error(), strings.TrimSpace(string(out)))
		return result, nil
	}

	result.Success = true
	result.Message = strings.TrimSpace(string(out))
	return result, nil
}

// mapActionToNetsh maps internal action to netsh action.
func mapActionToNetsh(action string) string {
	switch strings.ToLower(action) {
	case "allow", "enable":
		return "allow"
	case "deny", "block", "disable", "reject":
		return "block"
	default:
		return "block"
	}
}

// mapDirToNetsh maps direction to netsh direction.
func mapDirToNetsh(dir string) string {
	switch strings.ToLower(dir) {
	case "out":
		return "out"
	default:
		return "in"
	}
}
