#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
calculadora.py - Calculadora de funciones matematicas y limites
Autor: Moskov
Descripcion: Evalua funciones, calcula limites y derivadas usando sympy.
"""

import sympy as sp

# Variable simbolica global
x = sp.symbols("x")


def ingresar_funcion():
    """Solicita al usuario una funcion matematica en terminos de x."""
    while True:
        try:
            entrada = input("\n  Introduce la funcion en terminos de x: ")
            funcion = sp.sympify(entrada)
            print(f"  Funcion registrada: f(x) = {funcion}")
            return funcion
        except (sp.SympifyError, ValueError):
            print("  [!] Funcion no valida. Usa sintaxis como: x**2 + 3*x - 1")


def evaluar_funcion(f):
    """Evalua la funcion en un punto dado."""
    try:
        valor = float(input("  Introduce el valor de x: "))
        resultado = f.subs(x, valor)
        print(f"  f({valor}) = {resultado}")
    except ValueError:
        print("  [!] Valor no valido. Introduce un numero.")


def calcular_limite(f):
    """Calcula el limite de la funcion cuando x tiende a un valor."""
    try:
        valor = float(input("  Introduce el valor hacia el que tiende x: "))
        print("  Direccion del limite:")
        print("    1) Por la izquierda (-)")
        print("    2) Por la derecha (+)")
        print("    3) Ambos lados")
        direccion = input("  Selecciona (1/2/3): ").strip()

        if direccion == "1":
            limite = sp.limit(f, x, valor, dir="-")
            print(f"  Limite por la izquierda cuando x -> {valor} = {limite}")
        elif direccion == "2":
            limite = sp.limit(f, x, valor, dir="+")
            print(f"  Limite por la derecha cuando x -> {valor} = {limite}")
        else:
            limite = sp.limit(f, x, valor)
            print(f"  Limite cuando x -> {valor} = {limite}")
    except ValueError:
        print("  [!] Valor no valido.")


def calcular_derivada(f):
    """Calcula la derivada de la funcion."""
    derivada = sp.diff(f, x)
    print(f"  f'(x) = {derivada}")


def main():
    print("\n  ===================================")
    print("   Calculadora de Funciones y Limites")
    print("  ===================================")

    funcion = ingresar_funcion()

    while True:
        print("\n  Que deseas hacer?")
        print("  1. Evaluar funcion en un punto")
        print("  2. Calcular limite")
        print("  3. Calcular derivada")
        print("  4. Cambiar funcion")
        print("  5. Salir")

        opcion = input("\n  Selecciona una opcion: ").strip()

        if opcion == "1":
            evaluar_funcion(funcion)
        elif opcion == "2":
            calcular_limite(funcion)
        elif opcion == "3":
            calcular_derivada(funcion)
        elif opcion == "4":
            funcion = ingresar_funcion()
        elif opcion == "5":
            print("\n  Hasta luego!\n")
            break
        else:
            print("  [!] Opcion no valida.")


if __name__ == "__main__":
    main()
