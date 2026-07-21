#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
estado_pc.py - Herramienta de diagnostico del sistema con interfaz grafica
Autor: Moskov
Descripcion: Muestra informacion del sistema (CPU, RAM, disco, GPU) y puertos abiertos.
Dependencias: psutil, tkinter (incluido en Python), GPUtil (opcional)
"""

import tkinter as tk
from tkinter import messagebox, scrolledtext
import platform
import psutil
import subprocess


def info_sistema():
    """Recopila y muestra informacion detallada del sistema."""
    info = ""
    info += f"{'='*50}\n"
    info += f"  INFORMACION DEL SISTEMA\n"
    info += f"{'='*50}\n\n"
    info += f"  Hostname:    {platform.node()}\n"
    info += f"  OS:          {platform.system()} {platform.release()}\n"
    info += f"  Kernel:      {platform.version()}\n"
    info += f"  Arquitectura:{platform.machine()}\n\n"

    # CPU
    info += f"  CPU:         {psutil.cpu_percent(interval=1)}% de uso\n"
    info += f"  Nucleos:     {psutil.cpu_count(logical=True)} logicos / {psutil.cpu_count(logical=False)} fisicos\n\n"

    # RAM
    ram = psutil.virtual_memory()
    info += f"  RAM:         {ram.percent}% usada\n"
    info += f"               {round(ram.used / (1024**3), 2)} GB / {round(ram.total / (1024**3), 2)} GB\n\n"

    # Disco
    disco = psutil.disk_usage('/')
    info += f"  Disco (/):   {disco.percent}% usado\n"
    info += f"               {round(disco.used / (1024**3), 2)} GB / {round(disco.total / (1024**3), 2)} GB\n\n"

    # GPU (opcional)
    try:
        import GPUtil
        gpus = GPUtil.getGPUs()
        for gpu in gpus:
            info += f"  GPU:         {gpu.name}\n"
            info += f"               Carga: {gpu.load*100:.1f}% | VRAM: {gpu.memoryUsed}/{gpu.memoryTotal} MB\n"
    except ImportError:
        info += "  GPU:         GPUtil no instalado (pip install gputil)\n"

    # Bateria
    bateria = psutil.sensors_battery()
    if bateria:
        estado = "Cargando" if bateria.power_plugged else "Descargando"
        info += f"\n  Bateria:     {bateria.percent}% [{estado}]\n"

    mostrar_resultado("Informacion del Sistema", info)


def puertos_servicios():
    """Muestra los puertos abiertos y servicios activos."""
    comando = "ss -tuln" if platform.system() != "Windows" else "netstat -ano"
    try:
        resultado = subprocess.check_output(comando, shell=True, text=True)
        mostrar_resultado("Puertos Abiertos / Servicios", resultado)
    except subprocess.CalledProcessError as e:
        mostrar_resultado("Error", f"No se pudo ejecutar el comando:\n{e}")


def mostrar_resultado(titulo, contenido):
    """Abre una ventana con el resultado formateado."""
    ventana = tk.Toplevel(root)
    ventana.title(titulo)
    ventana.geometry("750x450")
    ventana.configure(bg="#2b2b3d")

    texto = scrolledtext.ScrolledText(
        ventana, wrap=tk.WORD,
        bg="#1e1e2e", fg="#ffffff",
        font=("Hack Nerd Font", 10),
        insertbackground="#ffffff"
    )
    texto.insert(tk.INSERT, contenido)
    texto.config(state=tk.DISABLED)
    texto.pack(expand=True, fill='both', padx=5, pady=5)


def salir():
    """Confirma y cierra la aplicacion."""
    if messagebox.askokcancel("Salir", "Deseas cerrar la aplicacion?"):
        root.destroy()


# --- Interfaz principal ---
root = tk.Tk()
root.title("Diagnostico del Sistema - Moskov")
root.geometry("420x320")
root.configure(bg="#2b2b3d")

tk.Label(
    root, text="Diagnostico del Sistema",
    font=("Hack Nerd Font", 16, "bold"),
    bg="#2b2b3d", fg="#ffffff"
).pack(pady=25)

btn_style = {"width": 30, "bg": "#363649", "fg": "#ffffff", "font": ("Hack Nerd Font", 11), "relief": "flat"}

tk.Button(root, text="  Informacion del Sistema", command=info_sistema, **btn_style).pack(pady=8)
tk.Button(root, text="  Puertos / Servicios", command=puertos_servicios, **btn_style).pack(pady=8)
tk.Button(root, text="  Salir", command=salir, **btn_style).pack(pady=8)

root.mainloop()
