#!/bin/bash

# Función para mostrar el mensaje de bienvenida y las opciones del menú
mostrar_mensaje_bienvenida() {
    clear
    echo "¡Bienvenido al programa de gestión de unidades compartidas!"
    echo ""
    echo "Por favor, selecciona una opción:"
    echo "1. Verificar Requisitos"
    echo "2. Compartir Unidad de Red"
    echo "3. Opción 3"
    echo "4. Opción 4"
    echo "5. Salir"
    echo ""
}

# Función para mostrar el encabezado de Programa Unidad Compartida
mostrar_encabezado() {
    clear
    echo "======================================"
    echo "        Programa Unidad Compartida    "
    echo "======================================"
    echo ""
}

# Función para verificar si Samba está instalado y mostrar su versión y la información del sistema
verificar_samba() {
    mostrar_encabezado
    if command -v smbd &>/dev/null; then
        echo "************************************"
        echo "* ¡Samba está INSTALADO en el sistema! *"
        echo "************************************"
        echo ""
        echo "Versión de Samba:"
        smbd --version | head -n 1
    else
        echo "Samba no está instalado."
    fi
    echo ""
    echo "Información del sistema:"
    echo "======================="
    echo "Hostname: $(hostname)"
    echo "Sistema Operativo: $(uname)"
    echo "Versión del Kernel: $(uname -r)"
    echo "Memoria RAM: $(free -h | awk 'NR==2 {print $2}')"
    echo "Espacio en Disco: $(df -h / | awk 'NR==2 {print $2 " total (" $4 " disponible)"}')"
    echo "Fecha y Hora: $(date)"
    echo ""
    read -p "Presiona Enter para volver al menú..." tecla
}

# Función para compartir la unidad de red
compartir_unidad_red() {
    mostrar_encabezado
    echo "**********************************************"
    echo "*             Unidad de Red Actual            *"
    echo "**********************************************"
    echo ""
    local ruta_unidad="${HOME}/Desktop/Network_Drive/"
    echo "Ruta de la unidad de red: $ruta_unidad"
    echo ""
    read -p "¿Desea continuar con esta ruta? [s/n]: " continuar
    if [[ $continuar =~ ^[Ss]$ ]]; then
        compartir_con_samba "$ruta_unidad"
    elif [[ $continuar =~ ^[Nn]$ ]]; then
        read -p "Ingrese la nueva ruta de la unidad de red: " nueva_ruta
        compartir_con_samba "$nueva_ruta"
    else
        echo "Respuesta no válida."
    fi
    read -p "Presiona Enter para volver al menú..." tecla
}

# Función para compartir la unidad con Samba
compartir_con_samba() {
    local ruta_compartir=$1
    mostrar_encabezado
    echo "**********************************************"
    echo "*       Compartiendo unidad: $ruta_compartir      *"
    echo "**********************************************"
    echo ""
    echo "Configurando la carpeta compartida en Samba..."
    # Configurar la carpeta compartida en Samba
    sudo mkdir -p "$ruta_compartir"
    sudo chown nobody:nogroup "$ruta_compartir"
    sudo chmod 777 "$ruta_compartir"
    sudo bash -c "echo '[Network_Drive]' >> /etc/samba/smb.conf"
    sudo bash -c "echo '   path = $ruta_compartir' >> /etc/samba/smb.conf"
    sudo bash -c "echo '   browseable = yes' >> /etc/samba/smb.conf"
    sudo bash -c "echo '   read only = no' >> /etc/samba/smb.conf"
    sudo bash -c "echo '   guest ok = yes' >> /etc/samba/smb.conf"
    echo "Reiniciando el servicio Samba..."
    sudo systemctl restart smbd
    echo "************************************"
    echo "* La unidad de red se ha compartido correctamente. *"
    echo "************************************"
    mostrar_menu_unidad_compartida "$ruta_compartir"
}

# Función para mostrar el menú cuando la unidad está compartida
mostrar_menu_unidad_compartida() {
    local ruta_unidad="$1"
    echo ""
    echo "Menú Unidad Compartida:"
    echo "1. Dejar de compartir unidad de red"
    echo "2. Volver al menú principal"
    echo "3. Salir del programa"
    echo ""
    read -p "Selecciona una opción: " opcion
    case $opcion in
        1)
            dejar_de_compartir_unidad "$ruta_unidad"
            ;;
        2)
            mostrar_mensaje_bienvenida
            ;;
        3)
            salir_del_programa
            ;;
        *)
            echo "Opción no válida."
            mostrar_menu_unidad_compartida "$ruta_unidad"
            ;;
    esac
}

# Función para dejar de compartir la unidad de red
dejar_de_compartir_unidad() {
    local ruta_unidad="$1"
    mostrar_encabezado
    read -p "¿Estás seguro de dejar de compartir la unidad de red? [s/n]: " respuesta
    if [[ $respuesta =~ ^[Ss]$ ]]; then
        # Aquí pondrías el código para dejar de compartir la unidad
        echo "Dejar de compartir la unidad de red."
        sudo systemctl stop smbd
        sudo systemctl stop nmbd
        read -p "Presiona Enter para volver al menú..." tecla
        mostrar_mensaje_bienvenida
    elif [[ $respuesta =~ ^[Nn]$ ]]; then
        mostrar_menu_unidad_compartida "$ruta_unidad"
    else
        echo "Respuesta no válida."
        dejar_de_compartir_unidad "$ruta_unidad"
    fi
}

# Función para salir del programa
salir_del_programa() {
    mostrar_encabezado
    read -p "¿Estás seguro de salir del programa? [s/n]: " respuesta
    if [[ $respuesta =~ ^[Ss]$ ]]; then
        # Aquí pondrías el código para finalizar el programa
        echo "¡Hasta luego!"
        sudo systemctl stop smbd
        sudo systemctl stop nmbd
        exit 0
    elif [[ $respuesta =~ ^[Nn]$ ]]; then
        mostrar_menu_unidad_compartida "$ruta_unidad"
    else
        echo "Respuesta no válida."
        salir_del_programa
    fi
}

# Función principal
main() {
    while true; do
        mostrar_mensaje_bienvenida
        read -p "Ingresa el número de la opción que deseas ejecutar: " opcion

        case $opcion in
            1)
                verificar_samba
                ;;
            2)
                compartir_unidad_red
                ;;
            3)
                mostrar_encabezado
                echo "Has seleccionado la opción 3."
                read -p "Presiona Enter para volver al menú..." tecla
                ;;
            4)
                mostrar_encabezado
                echo "Has seleccionado la opción 4."
                read -p "Presiona Enter para volver al menú..." tecla
                ;;
            5)
                salir_del_programa
                ;;
            *)
                mostrar_encabezado
                echo "Opción no válida. Por favor, ingresa un número válido."
                read -p "Presiona Enter para volver al menú..." tecla
                ;;
        esac
    done
}

# Llamar a la función principal
main
