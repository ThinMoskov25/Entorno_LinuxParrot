#!/usr/bin/env bash
##############################################################################
# run_docker_test.sh — Despliegue y validación aislada de install_environment.sh
# Moskov Environment v3.0 — Docker Test Harness
##############################################################################
set -euo pipefail

# ─── Configuración ──────────────────────────────────────────────────────────
IMAGE_NAME="moskov-env-test"
CONTAINER_NAME="moskov-env-runner"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE_PATH="${SCRIPT_DIR}/Dockerfile"

# Repositorio del script (ajustar si es necesario)
REPO_URL="${MOSKOV_REPO_URL:-https://github.com/moskov/environment.git}"
SCRIPT_NAME="install_environment.sh"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── Funciones de utilidad ───────────────────────────────────────────────────
log_info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[PASS]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_fail()  { echo -e "${RED}[FAIL]${NC}  $*"; }
log_header(){ echo -e "\n${CYAN}════════════════════════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}\n"; }

TESTS_PASSED=0
TESTS_FAILED=0

assert_check() {
    local description="$1"
    local exit_code="$2"
    if [[ "$exit_code" -eq 0 ]]; then
        log_ok "$description"
        ((TESTS_PASSED++))
    else
        log_fail "$description"
        ((TESTS_FAILED++))
    fi
}

# ─── Limpieza automática (auto-cleanup) ─────────────────────────────────────
cleanup() {
    log_header "LIMPIEZA AUTOMÁTICA"

    # Detener y eliminar contenedor si existe
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Eliminando contenedor '${CONTAINER_NAME}'..."
        docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    fi

    # Eliminar imagen de pruebas
    if docker images --format '{{.Repository}}' | grep -q "^${IMAGE_NAME}$"; then
        log_info "Eliminando imagen '${IMAGE_NAME}'..."
        docker rmi -f "${IMAGE_NAME}" >/dev/null 2>&1 || true
    fi

    # Limpiar imágenes huérfanas (dangling)
    local dangling
    dangling=$(docker images -f "dangling=true" -q 2>/dev/null || true)
    if [[ -n "$dangling" ]]; then
        log_info "Eliminando imágenes huérfanas..."
        docker rmi $dangling >/dev/null 2>&1 || true
    fi

    log_ok "Sistema host limpio — sin residuos de contenedores ni imágenes."
}

# Ejecutar limpieza en caso de error o al finalizar
trap cleanup EXIT

# ─── Verificaciones previas ──────────────────────────────────────────────────
log_header "VERIFICACIONES PREVIAS"

if ! command -v docker &>/dev/null; then
    log_fail "Docker no está instalado o no está en el PATH."
    exit 1
fi

if ! docker info &>/dev/null; then
    log_fail "Docker daemon no está corriendo o el usuario no tiene permisos."
    log_info "Intenta: sudo systemctl start docker || sudo usermod -aG docker \$USER"
    exit 1
fi

log_ok "Docker disponible y funcional."

# ─── Fase 1: Construir imagen ────────────────────────────────────────────────
log_header "FASE 1: BUILD DE IMAGEN DE PRUEBAS"

log_info "Construyendo imagen '${IMAGE_NAME}' desde ${DOCKERFILE_PATH}..."
if docker build -t "${IMAGE_NAME}" -f "${DOCKERFILE_PATH}" "${SCRIPT_DIR}" 2>&1; then
    log_ok "Imagen '${IMAGE_NAME}' construida exitosamente."
else
    log_fail "Error al construir la imagen Docker."
    exit 1
fi

# ─── Fase 2: Preparar script de validación interna ───────────────────────────
log_header "FASE 2: PREPARAR VALIDACIONES INTERNAS"

VALIDATION_SCRIPT="${SCRIPT_DIR}/validate_inside_container.sh"

if [[ ! -f "$VALIDATION_SCRIPT" ]]; then
    log_fail "No se encontró validate_inside_container.sh en ${SCRIPT_DIR}"
    exit 1
fi

log_ok "Script de validación interna encontrado: ${VALIDATION_SCRIPT}"

# ─── Fase 3: Ejecutar contenedor con validaciones ────────────────────────────
log_header "FASE 3: EJECUCIÓN DE PRUEBAS EN CONTENEDOR"

log_info "Levantando contenedor '${CONTAINER_NAME}' en modo efímero (--rm)..."

# Ejecutar el contenedor con --rm para auto-limpieza
# Se montan ambos scripts: el instalador y el validador
INSTALL_SCRIPT="${SCRIPT_DIR}/install_environment.sh"
CONTAINER_EXIT_CODE=0
docker run --rm \
    --name "${CONTAINER_NAME}" \
    --hostname "moskov-testbox" \
    -e DEBIAN_FRONTEND=noninteractive \
    -e TERM=xterm-256color \
    -e NEEDRESTART_MODE=a \
    -e NEEDRESTART_SUSPEND=1 \
    -v "${VALIDATION_SCRIPT}:/tmp/validate.sh:ro" \
    -v "${INSTALL_SCRIPT}:/tmp/install_environment.sh:ro" \
    "${IMAGE_NAME}" \
    bash /tmp/validate.sh || CONTAINER_EXIT_CODE=$?

# ─── Fase 4: Resultado final ─────────────────────────────────────────────────
log_header "RESULTADO FINAL"

if [[ "$CONTAINER_EXIT_CODE" -eq 0 ]]; then
    log_ok "Todas las validaciones del entorno pasaron exitosamente."
    log_info "El script install_environment.sh puede ejecutarse de forma segura."
else
    log_fail "Algunas validaciones fallaron (exit code: ${CONTAINER_EXIT_CODE})."
    log_warn "Revisa los logs anteriores para identificar los problemas."
fi

echo ""
log_info "Contenedor eliminado automáticamente (--rm flag)."
log_info "La limpieza de imagen se ejecutará al finalizar (trap EXIT)."
echo ""

exit $CONTAINER_EXIT_CODE
