package logger

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// Logger provides thread-safe logging to file with timestamps.
type Logger struct {
	mu      sync.Mutex
	file    *os.File
	logger  *log.Logger
	logDir  string
	logPath string
}

// instance holds the singleton logger.
var (
	instance *Logger
	once     sync.Once
)

// Init initializes the global logger, creating the logs directory if needed.
// baseDir is the base directory where the "logs" folder will be created.
func Init(baseDir string) error {
	var initErr error

	once.Do(func() {
		logDir := filepath.Join(baseDir, "logs")
		if err := os.MkdirAll(logDir, 0755); err != nil {
			initErr = fmt.Errorf("no se pudo crear directorio de logs %q: %w", logDir, err)
			return
		}

		logPath := filepath.Join(logDir, "netaudit.log")
		f, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
		if err != nil {
			initErr = fmt.Errorf("no se pudo abrir archivo de log %q: %w", logPath, err)
			return
		}

		l := log.New(f, "", 0) // No prefix; we format manually

		instance = &Logger{
			file:    f,
			logger:  l,
			logDir:  logDir,
			logPath: logPath,
		}

		Info("═══ NetAudit iniciado ═══")
	})

	return initErr
}

// Close closes the log file. Call on application exit.
func Close() {
	if instance != nil && instance.file != nil {
		Info("═══ NetAudit finalizado ═══")
		instance.file.Close()
	}
}

// Info logs an informational message.
func Info(format string, args ...interface{}) {
	writeLog("INFO", format, args...)
}

// Warn logs a warning message.
func Warn(format string, args ...interface{}) {
	writeLog("WARN", format, args...)
}

// Error logs an error message.
func Error(format string, args ...interface{}) {
	writeLog("ERROR", format, args...)
}

// Action logs a user action or command execution.
func Action(format string, args ...interface{}) {
	writeLog("ACCIÓN", format, args...)
}

// Command logs a system command being executed.
func Command(format string, args ...interface{}) {
	writeLog("CMD", format, args...)
}

// writeLog formats and writes a log entry with timestamp.
func writeLog(level, format string, args ...interface{}) {
	if instance == nil {
		return
	}

	instance.mu.Lock()
	defer instance.mu.Unlock()

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	msg := fmt.Sprintf(format, args...)
	entry := fmt.Sprintf("[%s] [%s] %s", timestamp, level, msg)

	instance.logger.Println(entry)
}

// GetLogPath returns the path to the current log file.
func GetLogPath() string {
	if instance != nil {
		return instance.logPath
	}
	return ""
}
