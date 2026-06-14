"""Valida el modelo predictivo de ventas del TFM.

Este script se ejecuta despues del notebook 02. Lee las metricas y
predicciones generadas, compara el mejor modelo con el baseline y crea
salidas listas para memoria y Power BI.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUT_DATOS = PROJECT_ROOT / "outputs" / "datos"
DOC_DIR = PROJECT_ROOT / "documentacion"


def _to_numeric(df: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    result = df.copy()
    for column in columns:
        if column in result.columns:
            result[column] = pd.to_numeric(result[column], errors="coerce")
    return result


def _model_error_summary(predicciones: pd.DataFrame) -> pd.DataFrame:
    pred = _to_numeric(predicciones, ["real", "prediccion", "error", "error_abs"])
    rows = []
    for model, group in pred.groupby("modelo", sort=False):
        real_sum = group["real"].sum()
        abs_sum = group["error_abs"].sum()
        error_sum = group["error"].sum()
        rows.append(
            {
                "modelo": model,
                "filas_validacion": len(group),
                "real_total": real_sum,
                "prediccion_total": group["prediccion"].sum(),
                "wmape": abs_sum / real_sum * 100 if real_sum else pd.NA,
                "sesgo_pct": error_sum / real_sum * 100 if real_sum else pd.NA,
            }
        )
    return pd.DataFrame(rows)


def build_validation_outputs() -> dict[str, Path]:
    metrics_path = OUT_DATOS / "comparacion_ml_deep_learning.csv"
    if not metrics_path.exists():
        metrics_path = OUT_DATOS / "metricas_ml_ventas.csv"
    prediction_paths = [
        OUT_DATOS / "predicciones_ml_ventas.csv",
        OUT_DATOS / "predicciones_deep_learning_mlp.csv",
    ]

    if not metrics_path.exists():
        raise FileNotFoundError(f"No existe {metrics_path}")

    existing_prediction_paths = [path for path in prediction_paths if path.exists()]
    if not existing_prediction_paths:
        raise FileNotFoundError("No existen CSVs de predicciones ML/DL.")

    metricas = pd.read_csv(metrics_path)
    metricas = _to_numeric(metricas, ["MAE", "RMSE", "MAPE", "R2"])
    predicciones = pd.concat(
        [pd.read_csv(path, parse_dates=["fecha"]) for path in existing_prediction_paths],
        ignore_index=True,
    )

    error_summary = _model_error_summary(predicciones)
    metricas = metricas.merge(error_summary, on="modelo", how="left")
    metricas = metricas.sort_values(["RMSE", "MAE"], ascending=True).reset_index(drop=True)

    baseline_name = "Baseline media movil 7d"
    baseline = metricas.loc[metricas["modelo"].eq(baseline_name)].iloc[0]
    best = metricas.iloc[0]

    metricas["mejora_rmse_vs_baseline_pct"] = (
        (baseline["RMSE"] - metricas["RMSE"]) / baseline["RMSE"] * 100
    )
    metricas["mejora_mae_vs_baseline_pct"] = (
        (baseline["MAE"] - metricas["MAE"]) / baseline["MAE"] * 100
    )
    metricas["decision"] = metricas["modelo"].apply(
        lambda model: "Modelo seleccionado" if model == best["modelo"] else "Modelo comparativo"
    )

    selected_predictions = predicciones[predicciones["modelo"].eq(best["modelo"])].copy()
    selected_predictions = _to_numeric(
        selected_predictions,
        ["real", "prediccion", "error", "error_abs"],
    )

    by_channel = (
        selected_predictions.groupby("canal", as_index=False)
        .agg(
            filas=("fecha", "size"),
            real_total=("real", "sum"),
            prediccion_total=("prediccion", "sum"),
            mae=("error_abs", "mean"),
            error_total=("error", "sum"),
            error_abs_total=("error_abs", "sum"),
        )
        .sort_values("mae", ascending=False)
    )
    by_channel["wmape"] = by_channel["error_abs_total"] / by_channel["real_total"] * 100
    by_channel["sesgo_pct"] = by_channel["error_total"] / by_channel["real_total"] * 100

    by_category = (
        selected_predictions.groupby("categoria", as_index=False)
        .agg(
            filas=("fecha", "size"),
            real_total=("real", "sum"),
            prediccion_total=("prediccion", "sum"),
            mae=("error_abs", "mean"),
            error_total=("error", "sum"),
            error_abs_total=("error_abs", "sum"),
        )
        .sort_values("mae", ascending=False)
    )
    by_category["wmape"] = by_category["error_abs_total"] / by_category["real_total"] * 100
    by_category["sesgo_pct"] = by_category["error_total"] / by_category["real_total"] * 100

    validation_path = OUT_DATOS / "validacion_modelo_predictivo.csv"
    channel_path = OUT_DATOS / "validacion_modelo_por_canal.csv"
    category_path = OUT_DATOS / "validacion_modelo_por_categoria.csv"
    metricas.to_csv(validation_path, index=False)
    by_channel.to_csv(channel_path, index=False)
    by_category.to_csv(category_path, index=False)

    mejora_rmse = (baseline["RMSE"] - best["RMSE"]) / baseline["RMSE"] * 100
    mejora_mae = (baseline["MAE"] - best["MAE"]) / baseline["MAE"] * 100

    doc = f"""# Validacion del modelo predictivo

## Objetivo

El objetivo del modelo es predecir unidades vendidas por dia, canal y categoria. La finalidad de negocio no es acertar cada pedido individual, sino anticipar demanda agregada para apoyar decisiones de stock, promociones y planificacion comercial.

## Diseno de validacion

- Division temporal: entrenamiento con fechas antiguas y validacion con fechas posteriores.
- Baseline obligatorio: media movil de 7 dias.
- Modelos comparados: regresion lineal, Ridge, Random Forest, Gradient Boosting y MLP opcional.
- Metricas principales: MAE, RMSE, WMAPE, sesgo porcentual y R2.

## Resultado

- Modelo seleccionado: {best['modelo']}.
- RMSE del modelo: {best['RMSE']:.4f}.
- RMSE del baseline: {baseline['RMSE']:.4f}.
- Mejora RMSE frente al baseline: {mejora_rmse:.2f}%.
- Mejora MAE frente al baseline: {mejora_mae:.2f}%.
- WMAPE del modelo seleccionado: {best['wmape']:.2f}%.
- Sesgo agregado del modelo seleccionado: {best['sesgo_pct']:.2f}%.

## Interpretacion

El modelo seleccionado mejora al baseline, por lo que aporta valor frente a una regla sencilla de media movil. La mejora no es enorme, pero es defendible para un MVP analitico porque mantiene interpretabilidad y evita complejidad innecesaria.

El MAPE aparece elevado porque se predicen unidades por combinaciones de dia, canal y categoria, donde muchos valores reales son pequenos. En ese contexto, un error de 1 o 2 unidades dispara el porcentaje. Por eso se incorpora WMAPE y sesgo agregado, que son mas adecuados para planificacion de demanda.

## Decision de negocio

Para el TFM se recomienda usar {best['modelo']} como modelo principal. La red neuronal queda como comparacion tecnica: si no mejora claramente a modelos clasicos, no se justifica como solucion final.

## Uso en Power BI

Las predicciones se exportan a SQL Server en `gold.fact_prediccion_ventas` y se consumen desde la vista `gold.predicciones_ventas`. Esto permite que Power BI muestre venta real, venta predicha, error y riesgo de stock desde el servidor local.
"""
    DOC_DIR.mkdir(parents=True, exist_ok=True)
    (DOC_DIR / "VALIDACION_MODELO_PREDICTIVO.md").write_text(doc, encoding="utf-8")

    return {
        "validacion": validation_path,
        "canal": channel_path,
        "categoria": category_path,
        "documentacion": DOC_DIR / "VALIDACION_MODELO_PREDICTIVO.md",
    }


if __name__ == "__main__":
    outputs = build_validation_outputs()
    for name, path in outputs.items():
        print(f"{name}: {path}")