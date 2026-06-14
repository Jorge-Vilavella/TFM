"""Utilidades estadisticas para el TFM."""

from __future__ import annotations

import numpy as np
import pandas as pd


def detectar_outliers_iqr(df: pd.DataFrame, columna: str) -> pd.DataFrame:
    """Marca outliers con el criterio IQR."""
    serie = df[columna].dropna()
    q1 = serie.quantile(0.25)
    q3 = serie.quantile(0.75)
    iqr = q3 - q1
    limite_inferior = q1 - 1.5 * iqr
    limite_superior = q3 + 1.5 * iqr

    resultado = df.copy()
    resultado[f"{columna}_outlier_iqr"] = (
        (resultado[columna] < limite_inferior)
        | (resultado[columna] > limite_superior)
    )
    return resultado


def resumen_por_grupo(
    df: pd.DataFrame,
    grupo: str | list[str],
    metricas: list[str],
) -> pd.DataFrame:
    """Resume media, mediana, desviacion y percentiles por grupo."""
    resumen = df.groupby(grupo)[metricas].agg(
        ["count", "mean", "median", "std", "min", "max"]
    )
    resumen.columns = ["_".join(col).strip() for col in resumen.columns.values]
    return resumen.reset_index()


def matriz_correlacion(df: pd.DataFrame, columnas: list[str]) -> pd.DataFrame:
    """Calcula correlaciones Pearson sobre columnas numericas."""
    datos = df[columnas].replace([np.inf, -np.inf], np.nan).dropna()
    return datos.corr(numeric_only=True)


def interpretar_pvalor(pvalor: float, alpha: float = 0.05) -> str:
    """Traduce un p-valor a una frase simple."""
    if pd.isna(pvalor):
        return "No calculable"
    if pvalor < alpha:
        return "Diferencia estadisticamente significativa"
    return "No hay evidencia suficiente de diferencia estadistica"

