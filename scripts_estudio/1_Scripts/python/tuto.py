#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tuto.py - Calculadora basica de operaciones aritmeticas
Autor: Moskov
Descripcion: Calculadora interactiva con las 4 operaciones basicas + potencia y modulo.
"""


def suma(x, y):
    return x + y

def resta(x, y):
    return x - y

def multiplicacion(x, y):
    return x * y

def division(x, y):
    if y != 0:
        return x / y
    return "Error: Division por cero"

def potencia(x, y):
    return x ** y

def modulo(x, y):
    if y != 0:
        return x % y
    return "Error: Division por cero"


def obtener_numero(mensaje):
    """Solicita un numero al usuario con validacion."""
    while True:
        try:
            return float(input(mensaje))
        except ValueError:
            print("  [!] Ingresa un numero valido.")


def calculadora():
    """Menu principal de la calculadora."""
    operaciones = {
        "1": ("Sumar", "+", suma),
        "2": ("Restar", "-", resta),
        "3": ("Multiplicar", "*", multiplicacion),
        "4": ("Dividir", "/", division),
        "5": ("Potencia", "^", potencia),
        "6": ("Modulo", "%", modulo),
    }

    while True:
        print("\n  ========================")
        print("   Calculadora Aritmetica")
        print("  ========================")
        print("  Selecciona una operacion:")
        for key, (nombre, _, _) in operaciones.items():
            print(f"  {key}. {nombre}")
        print("  7. Salir")

        opcion = input("\n  Opcion: ").strip()

        if opcion == "7":
            print("\n  Hasta luego!\n")
            break

        if opcion not in operaciones:
            print("  [!] Opcion no valida.")
            continue

        nombre, simbolo, funcion = operaciones[opcion]
        num1 = obtener_numero("  Primer numero: ")
        num2 = obtener_numero("  Segundo numero: ")
        resultado = funcion(num1, num2)
        print(f"\n  {num1} {simbolo} {num2} = {resultado}")


if __name__ == "__main__":
    calculadora()
