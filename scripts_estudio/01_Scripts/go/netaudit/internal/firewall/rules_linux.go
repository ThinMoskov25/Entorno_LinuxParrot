//go:build linux

package firewall

import (
	"fmt"
	"os/exec"
	"strings"
)

// ApplyRule applies a firewall rule using iptables or ufw on Linux.
func ApplyRule(rule Rule) (*RuleResult, error) {
	// Determine which firewall tool is available
	tool := detectFirewallTool()

	switch tool {
	case "ufw":
		return applyUFWRule(rule)
	case "iptables":
		return applyIPTablesRule(rule)
	default:
		return nil, fmt.Errorf("no supported firewall tool found (install ufw or iptables)")
	}
}

// RemoveRule removes a firewall rule.
func RemoveRule(rule Rule) (*RuleResult, error) {
	tool := detectFirewallTool()

	switch tool {
	case "ufw":
		return removeUFWRule(rule)
	case "iptables":
		return removeIPTablesRule(rule)
	default:
		return nil, fmt.Errorf("no supported firewall tool found")
	}
}

// detectFirewallTool checks which firewall management tool is available.
func detectFirewallTool() string {
	// Prefer ufw for simpler syntax
	if _, err := exec.LookPath("ufw"); err == nil {
		return "ufw"
	}
	if _, err := exec.LookPath("iptables"); err == nil {
		return "iptables"
	}
	return ""
}

// applyUFWRule applies a rule using ufw.
func applyUFWRule(rule Rule) (*RuleResult, error) {
	action := mapActionToUFW(rule.Action)
	proto := rule.Protocol
	if proto == "both" {
		proto = ""
	}

	var args []string
	if rule.Dir == "in" || rule.Dir == "both" || rule.Dir == "" {
		args = buildUFWArgs(action, "in", rule.Port, proto)
	} else {
		args = buildUFWArgs(action, rule.Dir, rule.Port, proto)
	}

	cmd := exec.Command("ufw", args...)
	cmdStr := "ufw " + strings.Join(args, " ")

	out, err := cmd.CombinedOutput()
	result := &RuleResult{
		Rule:    rule,
		Command: cmdStr,
	}

	if err != nil {
		result.Success = false
		result.Message = fmt.Sprintf("ufw failed: %s - %s", err.Error(), strings.TrimSpace(string(out)))
		return result, nil
	}

	result.Success = true
	result.Message = strings.TrimSpace(string(out))
	return result, nil
}

// buildUFWArgs constructs ufw command arguments.
func buildUFWArgs(action, direction string, port int, proto string) []string {
	args := []string{action}

	if direction != "" {
		args = append(args, direction)
	}

	if proto != "" {
		args = append(args, "proto", proto)
	}

	args = append(args, "to", "any", "port", fmt.Sprintf("%d", port))
	return args
}

// removeUFWRule removes a ufw rule.
func removeUFWRule(rule Rule) (*RuleResult, error) {
	action := mapActionToUFW(rule.Action)
	proto := rule.Protocol
	if proto == "both" {
		proto = ""
	}

	dir := "in"
	if rule.Dir != "" && rule.Dir != "both" {
		dir = rule.Dir
	}

	args := []string{"delete"}
	args = append(args, buildUFWArgs(action, dir, rule.Port, proto)...)

	cmd := exec.Command("ufw", args...)
	cmdStr := "ufw " + strings.Join(args, " ")

	out, err := cmd.CombinedOutput()
	result := &RuleResult{
		Rule:    rule,
		Command: cmdStr,
	}

	if err != nil {
		result.Success = false
		result.Message = fmt.Sprintf("ufw delete failed: %s - %s", err.Error(), strings.TrimSpace(string(out)))
		return result, nil
	}

	result.Success = true
	result.Message = strings.TrimSpace(string(out))
	return result, nil
}

// applyIPTablesRule applies a rule using iptables.
func applyIPTablesRule(rule Rule) (*RuleResult, error) {
	target := mapActionToIPTables(rule.Action)
	chain := mapDirToChain(rule.Dir)
	proto := rule.Protocol
	if proto == "both" || proto == "" {
		proto = "tcp"
	}

	args := []string{
		"-A", chain,
		"-p", proto,
		"--dport", fmt.Sprintf("%d", rule.Port),
		"-j", target,
	}

	cmd := exec.Command("iptables", args...)
	cmdStr := "iptables " + strings.Join(args, " ")

	out, err := cmd.CombinedOutput()
	result := &RuleResult{
		Rule:    rule,
		Command: cmdStr,
	}

	if err != nil {
		result.Success = false
		result.Message = fmt.Sprintf("iptables failed: %s - %s", err.Error(), strings.TrimSpace(string(out)))
		return result, nil
	}

	result.Success = true
	result.Message = fmt.Sprintf("Rule applied: %s port %d/%s on chain %s", target, rule.Port, proto, chain)
	return result, nil
}

// removeIPTablesRule removes an iptables rule.
func removeIPTablesRule(rule Rule) (*RuleResult, error) {
	target := mapActionToIPTables(rule.Action)
	chain := mapDirToChain(rule.Dir)
	proto := rule.Protocol
	if proto == "both" || proto == "" {
		proto = "tcp"
	}

	args := []string{
		"-D", chain,
		"-p", proto,
		"--dport", fmt.Sprintf("%d", rule.Port),
		"-j", target,
	}

	cmd := exec.Command("iptables", args...)
	cmdStr := "iptables " + strings.Join(args, " ")

	out, err := cmd.CombinedOutput()
	result := &RuleResult{
		Rule:    rule,
		Command: cmdStr,
	}

	if err != nil {
		result.Success = false
		result.Message = fmt.Sprintf("iptables delete failed: %s - %s", err.Error(), strings.TrimSpace(string(out)))
		return result, nil
	}

	result.Success = true
	result.Message = fmt.Sprintf("Rule removed: %s port %d/%s from chain %s", target, rule.Port, proto, chain)
	return result, nil
}

// mapActionToUFW converts our action to ufw action.
func mapActionToUFW(action string) string {
	switch strings.ToLower(action) {
	case "allow", "enable":
		return "allow"
	case "deny", "block", "disable":
		return "deny"
	case "reject":
		return "reject"
	default:
		return "deny"
	}
}

// mapActionToIPTables converts our action to an iptables target.
func mapActionToIPTables(action string) string {
	switch strings.ToLower(action) {
	case "allow", "enable":
		return "ACCEPT"
	case "deny", "block", "disable":
		return "DROP"
	case "reject":
		return "REJECT"
	default:
		return "DROP"
	}
}

// mapDirToChain maps direction to iptables chain.
func mapDirToChain(dir string) string {
	switch strings.ToLower(dir) {
	case "in", "":
		return "INPUT"
	case "out":
		return "OUTPUT"
	default:
		return "INPUT"
	}
}
