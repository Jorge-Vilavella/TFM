# Validacion del modelo predictivo

## Objetivo

El objetivo del modelo es predecir unidades vendidas por dia, canal y categoria. La finalidad de negocio no es acertar cada pedido individual, sino anticipar demanda agregada para apoyar decisiones de stock, promociones y planificacion comercial.

## Diseno de validacion

- Division temporal: entrenamiento con fechas antiguas y validacion con fechas posteriores.
- Baseline obligatorio: media movil de 7 dias.
- Modelos comparados: regresion lineal, Ridge, Random Forest, Gradient Boosting y MLP opcional.
- Metricas principales: MAE, RMSE, WMAPE, sesgo porcentual y R2.

## Resultado

- Modelo seleccionado: Ridge.
- RMSE del modelo: 2.6652.
- RMSE del baseline: 2.8110.
- Mejora RMSE frente al baseline: 5.19%.
- Mejora MAE frente al baseline: 4.85%.
- WMAPE del modelo seleccionado: 46.02%.
- Sesgo agregado del modelo seleccionado: -0.05%.

## Interpretacion

El modelo seleccionado mejora al baseline, por lo que aporta valor frente a una regla sencilla de media movil. La mejora no es enorme, pero es defendible para un MVP analitico porque mantiene interpretabilidad y evita complejidad innecesaria.

El MAPE aparece elevado porque se predicen unidades por combinaciones de dia, canal y categoria, donde muchos valores reales son pequenos. En ese contexto, un error de 1 o 2 unidades dispara el porcentaje. Por eso se incorpora WMAPE y sesgo agregado, que son mas adecuados para planificacion de demanda.

## Decision de negocio

Para el TFM se recomienda usar Ridge como modelo principal. La red neuronal queda como comparacion tecnica: si no mejora claramente a modelos clasicos, no se justifica como solucion final.

## Uso en Power BI

Las predicciones se exportan a SQL Server en `gold.fact_prediccion_ventas` y se consumen desde la vista `gold.predicciones_ventas`. Esto permite que Power BI muestre venta real, venta predicha, error y riesgo de stock desde el servidor local.
