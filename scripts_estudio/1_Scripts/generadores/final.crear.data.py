#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
final.crear.data.py - Generador de base de datos de usuarios corporativos
Autor: Moskov
Descripcion: Genera un archivo Excel con 1000 usuarios ficticios para entornos
             de laboratorio (Active Directory, pruebas de red, etc.)
Dependencias: pandas, faker, unidecode, openpyxl
Uso: python3 final.crear.data.py
"""

import sys
import random
import pandas as pd
from faker import Faker
from unidecode import unidecode

# Configuracion
NUM_USUARIOS = 1000
DOMINIO = "vanced.com"
LOCALE = "es_CO"

# Inicializar generador
fake = Faker(LOCALE)

# Areas validas de la organizacion
AREAS = [
    'Apoyo', 'Area de Exploracion', 'Asistencia', 'Base de Datos', 'Desarrollo',
    'Facturacion', 'Programadores', 'Recursos Humanos', 'Sistemas',
    'Soporte Tecnico', 'Soporte Tecnologico', 'Tesoreria', 'Nomina',
    'Soporte Laboratorio', 'Almacen', 'Gestores', 'Monitoreo'
]

CONTRATOS = [
    'Contrato indefinido', 'Contrato temporal',
    'Contrato obra labor', 'Contrato pasantia', 'Contrato aprendizaje'
]

CONTRATOS_BASICOS = [
    'Contrato indefinido', 'Contrato temporal',
    'Contrato productivo', 'Contrato obra labor'
]

PREFIJOS_TEL = [300, 301, 302, 304, 305, 320, 315, 311, 350]


def generar_password():
    """Genera una contrasena alfanumerica de 8 caracteres."""
    return (
        random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ') +
        random.choice('abcdefghijklmnopqrstuvwxyz') +
        random.choice('abcdefghijklmnopqrstuvwxyz') +
        str(random.randint(0, 9)) +
        str(random.randint(0, 9)) +
        ''.join(random.choice('abcdefghijklmnopqrstuvwxyz') for _ in range(3))
    )


def generar_usuario(i, contadores):
    """Genera los datos de un usuario basado en su posicion y contadores."""
    first_name = unidecode(fake.first_name())
    last_name = unidecode(fake.last_name())
    second_last_name = unidecode(fake.last_name())

    # Tipo de documento
    if contadores['ce'] >= 150 or i < 600:
        doc_type = 'CC'
        doc_number = '1' + ''.join(random.choice('123456789') for _ in range(9))
    else:
        doc_type = 'CE'
        digits = 7 if i >= 600 else 8
        doc_number = ''.join(random.choice('123456789') for _ in range(digits))
        contadores['ce'] += 1

    # Area y tipo de contrato
    if contadores['gerente'] < 10:
        area = 'Gerente'
        contrato = 'Contrato indefinido'
        contadores['gerente'] += 1
    elif contadores['servicios'] < 50:
        area = 'Servicios Generales'
        contrato = random.choice(CONTRATOS_BASICOS)
        contadores['servicios'] += 1
    elif contadores['guardas'] < 20:
        area = 'Guardas de Seguridad'
        contrato = random.choice(CONTRATOS_BASICOS)
        contadores['guardas'] += 1
    else:
        area = random.choice(AREAS)
        contrato = random.choice(CONTRATOS)

    # Datos derivados
    email = f'{first_name.lower()}.{last_name.lower()}.vcd@{DOMINIO}'
    domain_user = f'{first_name.lower()}.{second_last_name.lower()}'
    password = generar_password()
    telefono = f'{random.choice(PREFIJOS_TEL)}{random.randint(1000000, 9999999)}'

    return [
        first_name, last_name, second_last_name,
        doc_type, doc_number, contrato, area,
        email, domain_user, password, telefono
    ]


def main():
    """Funcion principal: genera los datos y exporta a Excel."""
    print(f"\n  [+] Generando {NUM_USUARIOS} usuarios corporativos...")

    contadores = {'gerente': 0, 'servicios': 0, 'guardas': 0, 'ce': 0}
    usuarios = [generar_usuario(i, contadores) for i in range(NUM_USUARIOS)]

    columnas = [
        'Nombre', 'Primer Apellido', 'Segundo Apellido',
        'Tipo de Documento', 'Numero de Documento', 'Tipo de Contrato',
        'Area', 'Correo Corporativo', 'Usuario de Dominio',
        'Contrasena', 'Numero de Contacto'
    ]

    df = pd.DataFrame(usuarios, columns=columnas)

    # Nombre de archivo con numero aleatorio
    file_name = f'data.{random.randint(100, 999)}.xlsx'
    df.to_excel(file_name, index=False)

    print(f"  [+] Datos exportados a: {file_name}")
    print(f"  [+] Total usuarios: {len(df)}")
    print(f"      - Gerentes: {contadores['gerente']}")
    print(f"      - Servicios Generales: {contadores['servicios']}")
    print(f"      - Guardas: {contadores['guardas']}")
    print(f"      - Documentos CE: {contadores['ce']}")
    print()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n  [!] Cancelado por el usuario.")
        sys.exit(0)
    except ImportError as e:
        print(f"\n  [!] Dependencia faltante: {e}")
        print("      Instala con: pip install pandas faker unidecode openpyxl")
        sys.exit(1)
