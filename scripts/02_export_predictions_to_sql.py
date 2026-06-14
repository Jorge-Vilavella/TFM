"""Exporta la mejor prediccion generada por Python a SQL Server.

Lee las metricas y predicciones generadas por el notebook 02, selecciona el
modelo con menor RMSE y escribe sus predicciones en gold.fact_prediccion_ventas.
"""

from __future__ import annotations

from pathlib import Path
import sys

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = PROJECT_ROOT / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.append(str(SRC_DIR))

from conexion_sql import get_connection  # noqa: E402


OUT_DATOS = PROJECT_ROOT / "outputs" / "datos"


def _read_predictions() -> tuple[str, pd.DataFrame]:
    metrics_path = OUT_DATOS / "comparacion_ml_deep_learning.csv"
    if not metrics_path.exists():
        metrics_path = OUT_DATOS / "metricas_ml_ventas.csv"

    if not metrics_path.exists():
        raise FileNotFoundError("No se encontraron metricas de modelos en outputs/datos.")

    metricas = pd.read_csv(metrics_path)
    metricas["RMSE"] = pd.to_numeric(metricas["RMSE"], errors="coerce")
    best_model = metricas.sort_values("RMSE").iloc[0]["modelo"]

    prediction_frames = []
    for file_name in ["predicciones_ml_ventas.csv", "predicciones_deep_learning_mlp.csv"]:
        path = OUT_DATOS / file_name
        if path.exists():
            prediction_frames.append(pd.read_csv(path, parse_dates=["fecha"]))

    if not prediction_frames:
        raise FileNotFoundError("No se encontraron predicciones en outputs/datos.")

    predicciones = pd.concat(prediction_frames, ignore_index=True)
    predicciones = predicciones[predicciones["modelo"] == best_model].copy()
    if predicciones.empty:
        raise ValueError(f"No hay predicciones para el mejor modelo: {best_model}")

    return best_model, predicciones


def export_predictions() -> int:
    best_model, predicciones = _read_predictions()

    rows = []
    for row in predicciones.itertuples(index=False):
        rows.append(
            (
                pd.Timestamp(row.fecha).date(),
                str(row.canal),
                str(row.categoria),
                str(row.modelo),
                None if pd.isna(row.real) else float(row.real),
                float(row.prediccion),
                None if pd.isna(row.error) else float(row.error),
                None if pd.isna(row.error_abs) else float(row.error_abs),
            )
        )

    insert_sql = """
    INSERT INTO gold.fact_prediccion_ventas
    (
        fecha,
        canal,
        categoria,
        modelo,
        real_unidades,
        prediccion_unidades,
        error_unidades,
        error_abs_unidades
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    """

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("TRUNCATE TABLE gold.fact_prediccion_ventas;")
        cursor.fast_executemany = True
        cursor.executemany(insert_sql, rows)
        conn.commit()

    print(f"Modelo exportado a SQL: {best_model}")
    print(f"Filas insertadas en gold.fact_prediccion_ventas: {len(rows)}")
    return len(rows)


if __name__ == "__main__":
    export_predictions()

