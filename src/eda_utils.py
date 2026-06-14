"""Funciones auxiliares para el notebook de EDA."""

from __future__ import annotations

from pathlib import Path

import pandas as pd


def resumen_calidad(df: pd.DataFrame, nombre: str) -> pd.DataFrame:
    """Resumen compacto de calidad para un DataFrame."""
    return pd.DataFrame(
        {
            "dataset": [nombre],
            "filas": [len(df)],
            "columnas": [df.shape[1]],
            "duplicados": [int(df.duplicated().sum())],
            "nulos_totales": [int(df.isna().sum().sum())],
            "columnas_con_nulos": [int((df.isna().sum() > 0).sum())],
        }
    )


def tabla_nulos(df: pd.DataFrame) -> pd.DataFrame:
    """Devuelve columnas con nulos y su porcentaje."""
    total = len(df)
    nulos = df.isna().sum()
    resultado = (
        pd.DataFrame(
            {
                "columna": nulos.index,
                "nulos": nulos.values,
                "porcentaje_nulos": (nulos.values / total * 100) if total else 0,
            }
        )
        .query("nulos > 0")
        .sort_values(["porcentaje_nulos", "nulos"], ascending=False)
        .reset_index(drop=True)
    )
    return resultado


def perfil_numerico(df: pd.DataFrame) -> pd.DataFrame:
    """Describe columnas numericas con metricas utiles para EDA."""
    numeric = df.select_dtypes(include="number")
    if numeric.empty:
        return pd.DataFrame()

    desc = numeric.describe().T
    desc["nulos"] = numeric.isna().sum()
    desc["ceros"] = (numeric == 0).sum()
    desc["negativos"] = (numeric < 0).sum()
    return desc.reset_index().rename(columns={"index": "columna"})


def asegurar_directorio(ruta: str | Path) -> Path:
    """Crea un directorio si no existe y devuelve su Path."""
    path = Path(ruta)
    path.mkdir(parents=True, exist_ok=True)
    return path

