package cli

import (
	"fmt"
	"strings"
)

// Table provides formatted table output for the CLI.
type Table struct {
	Headers []string
	Rows    [][]string
	Widths  []int
}

// NewTable creates a new table with the given headers.
func NewTable(headers ...string) *Table {
	widths := make([]int, len(headers))
	for i, h := range headers {
		widths[i] = len(h)
	}
	return &Table{
		Headers: headers,
		Widths:  widths,
	}
}

// AddRow adds a data row to the table.
func (t *Table) AddRow(cols ...string) {
	// Pad or truncate to match header count
	row := make([]string, len(t.Headers))
	for i := range row {
		if i < len(cols) {
			row[i] = cols[i]
		}
		if len(row[i]) > t.Widths[i] {
			t.Widths[i] = len(row[i])
		}
	}
	t.Rows = append(t.Rows, row)
}

// Render returns the formatted table as a string.
func (t *Table) Render() string {
	var sb strings.Builder

	// Calculate total width
	totalWidth := 0
	for _, w := range t.Widths {
		totalWidth += w + 3 // padding + separator
	}
	totalWidth += 1

	// Top border
	sb.WriteString(t.borderLine("┌", "┬", "┐"))
	sb.WriteByte('\n')

	// Header row
	sb.WriteString(t.formatRow(t.Headers))
	sb.WriteByte('\n')

	// Header separator
	sb.WriteString(t.borderLine("├", "┼", "┤"))
	sb.WriteByte('\n')

	// Data rows
	for _, row := range t.Rows {
		sb.WriteString(t.formatRow(row))
		sb.WriteByte('\n')
	}

	// Bottom border
	sb.WriteString(t.borderLine("└", "┴", "┘"))
	sb.WriteByte('\n')

	return sb.String()
}

// Print outputs the table to stdout.
func (t *Table) Print() {
	fmt.Print(t.Render())
}

// formatRow formats a single row with padding.
func (t *Table) formatRow(cols []string) string {
	var sb strings.Builder
	sb.WriteString("│")
	for i, col := range cols {
		width := t.Widths[i]
		sb.WriteString(fmt.Sprintf(" %-*s │", width, col))
	}
	return sb.String()
}

// borderLine creates a horizontal border line.
func (t *Table) borderLine(left, mid, right string) string {
	var sb strings.Builder
	sb.WriteString(left)
	for i, w := range t.Widths {
		sb.WriteString(strings.Repeat("─", w+2))
		if i < len(t.Widths)-1 {
			sb.WriteString(mid)
		}
	}
	sb.WriteString(right)
	return sb.String()
}
