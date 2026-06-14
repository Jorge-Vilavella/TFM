"""Utilidades de visualizacion y export para el TFM."""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


def guardar_figura(nombre: str, carpeta: str | Path, dpi: int = 150) -> Path:
    """Guarda la figura activa en PNG."""
    carpeta = Path(carpeta)
    carpeta.mkdir(parents=True, exist_ok=True)
    destino = carpeta / nombre
    plt.tight_layout()
    plt.savefig(destino, dpi=dpi, bbox_inches="tight")
    return destino


def grafico_real_vs_predicho(
    df: pd.DataFrame,
    fecha_col: str = "fecha",
    real_col: str = "real",
    pred_col: str = "prediccion",
    titulo: str = "Real vs prediccion",
):
    """Grafico temporal comparando valores reales y predichos."""
    fig, ax = plt.subplots(figsize=(14, 5))
    sns.lineplot(data=df, x=fecha_col, y=real_col, ax=ax, label="Real")
    sns.lineplot(data=df, x=fecha_col, y=pred_col, ax=ax, label="Prediccion")
    ax.set_title(titulo)
    ax.set_xlabel("Fecha")
    ax.set_ylabel("Valor")
    ax.tick_params(axis="x", rotation=45)
    return fig, ax

