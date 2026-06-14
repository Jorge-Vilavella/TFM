"""Funciones de preparacion y evaluacion de modelos para el TFM."""

from __future__ import annotations

import numpy as np
import pandas as pd


def crear_features_temporales(df: pd.DataFrame, fecha_col: str = "fecha") -> pd.DataFrame:
    """Crea variables temporales utiles para ventas diarias."""
    resultado = df.copy()
    resultado[fecha_col] = pd.to_datetime(resultado[fecha_col])
    resultado["dia_mes"] = resultado[fecha_col].dt.day
    resultado["semana_anio"] = resultado[fecha_col].dt.isocalendar().week.astype(int)
    resultado["mes"] = resultado[fecha_col].dt.month
    resultado["trimestre"] = resultado[fecha_col].dt.quarter
    resultado["dia_semana"] = resultado[fecha_col].dt.dayofweek + 1
    resultado["es_fin_de_semana"] = resultado["dia_semana"].isin([6, 7]).astype(int)
    resultado["dias_desde_inicio"] = (
        resultado[fecha_col] - resultado[fecha_col].min()
    ).dt.days
    return resultado


def crear_lags_por_grupo(
    df: pd.DataFrame,
    grupo_cols: list[str],
    objetivo: str,
    lags: list[int] | None = None,
    ventanas: list[int] | None = None,
) -> pd.DataFrame:
    """Crea retardos y medias moviles por grupo para series temporales."""
    lags = lags or [1, 7, 14, 30]
    ventanas = ventanas or [7, 14, 30]

    resultado = df.sort_values(grupo_cols + ["fecha"]).copy()
    grouped = resultado.groupby(grupo_cols, sort=False)[objetivo]

    for lag in lags:
        resultado[f"{objetivo}_lag_{lag}"] = grouped.shift(lag)

    for ventana in ventanas:
        resultado[f"{objetivo}_media_{ventana}"] = grouped.transform(
            lambda s: s.shift(1).rolling(ventana, min_periods=3).mean()
        )

    return resultado


def train_test_temporal(
    df: pd.DataFrame,
    fecha_col: str,
    test_ratio: float = 0.2,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Divide un dataset temporal respetando el orden cronologico."""
    ordenado = df.sort_values(fecha_col).copy()
    fechas = ordenado[fecha_col].drop_duplicates().sort_values()
    corte_idx = max(1, int(len(fechas) * (1 - test_ratio)))
    fecha_corte = fechas.iloc[corte_idx - 1]

    train = ordenado[ordenado[fecha_col] <= fecha_corte].copy()
    test = ordenado[ordenado[fecha_col] > fecha_corte].copy()
    return train, test


def metricas_regresion(y_real, y_pred) -> dict[str, float]:
    """Metricas habituales de regresion sin depender de versiones concretas."""
    y_real = np.asarray(y_real, dtype=float)
    y_pred = np.asarray(y_pred, dtype=float)
    error = y_real - y_pred
    mae = np.mean(np.abs(error))
    rmse = np.sqrt(np.mean(error**2))
    denominador = np.where(y_real == 0, np.nan, y_real)
    mape = np.nanmean(np.abs(error / denominador)) * 100
    ss_res = np.sum(error**2)
    ss_tot = np.sum((y_real - np.mean(y_real)) ** 2)
    r2 = 1 - ss_res / ss_tot if ss_tot != 0 else np.nan
    total_real = np.sum(y_real)
    wmape = (
        np.sum(np.abs(error)) / total_real * 100
        if total_real != 0
        else np.nan
    )
    sesgo_pct = (
        np.sum(error) / total_real * 100
        if total_real != 0
        else np.nan
    )
    return {
        "MAE": mae,
        "RMSE": rmse,
        "MAPE": mape,
        "WMAPE": wmape,
        "R2": r2,
        "Sesgo_pct": sesgo_pct,
    }


def preparar_resultados_prediccion(
    base: pd.DataFrame,
    y_real,
    y_pred,
    nombre_modelo: str,
) -> pd.DataFrame:
    """Devuelve DataFrame con real, predicho y error."""
    resultado = base.copy()
    resultado["modelo"] = nombre_modelo
    resultado["real"] = np.asarray(y_real, dtype=float)
    resultado["prediccion"] = np.asarray(y_pred, dtype=float)
    resultado["error"] = resultado["real"] - resultado["prediccion"]
    resultado["error_abs"] = resultado["error"].abs()
    return resultado

