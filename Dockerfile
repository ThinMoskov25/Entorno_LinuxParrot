##############################################################################
# Dockerfile — Entorno de pruebas aislado para install_environment.sh
# Base: Debian 12 (Bookworm) — compatible con Moskov Environment v3.0
##############################################################################
FROM debian:12

LABEL maintainer="moskov-devops"
LABEL description="Isolated test container for Moskov Environment v3.0 installer"

# Evitar prompts interactivos de APT/dpkg
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Instalar dependencias mínimas de bootstrap
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    sudo \
    curl \
    wget \
    procps \
    kmod \
    systemd \
    psmisc \
    ca-certificates \
    locales \
    lsb-release \
    apt-utils \
    gnupg2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configurar locale UTF-8
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Crear usuario sin privilegios con sudo sin contraseña
RUN useradd -m -s /bin/bash -G sudo testuser \
    && echo "testuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/testuser \
    && chmod 0440 /etc/sudoers.d/testuser

# Crear estructura base de directorios que el script espera
RUN mkdir -p /home/testuser/Desktop /home/testuser/.config \
    && chown -R testuser:testuser /home/testuser

# Simular logname/who (no hay sesión TTY real en Docker)
RUN echo '#!/bin/bash\necho testuser' > /usr/local/bin/logname \
    && chmod +x /usr/local/bin/logname

# Directorio de trabajo
WORKDIR /home/testuser

# Cambiar al usuario de pruebas
USER testuser

# Punto de entrada por defecto
CMD ["/bin/bash"]
