"""Comprobacion rapida del entorno local del TFM.

Este script no modifica datos. Solo verifica:
- version de Python;
- paquetes principales;
- drivers ODBC disponibles;
- conexion a la base local si pyodbc esta instalado.
"""

from __future__ import annotations

import importlib
import platform
import sys


REQUIRED_PACKAGES = [
    "pandas",
    "numpy",
    "matplotlib",
    "seaborn",
    "sklearn",
    "scipy",
    "statsmodels",
    "pyodbc",
]


def check_import(package: str) -> tuple[str, str]:
    try:
        module = importlib.import_module(package)
        version = getattr(module, "__version__", "sin version")
        return "OK", version
    except Exception as exc:  # pragma: no cover - script diagnostico
        return "ERROR", str(exc)


def main() -> None:
    print("Python:", sys.version.replace("\n", " "))
    print("Sistema:", platform.platform())
    print()

    print("Paquetes:")
    for package in REQUIRED_PACKAGES:
        status, detail = check_import(package)
        print(f"- {package}: {status} ({detail})")

    print()
    try:
        import pyodbc

        print("Drivers ODBC:")
        for driver in pyodbc.drivers():
            print(f"- {driver}")
    except Exception as exc:
        print("No se pudieron listar drivers ODBC:", exc)


if __name__ == "__main__":
    main()

