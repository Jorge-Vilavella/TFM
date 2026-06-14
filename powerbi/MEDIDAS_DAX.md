# Medidas DAX

Recomendacion: al cargar las tablas en Power BI, renombrarlas asi:

- `gold.ventas_powerbi` -> `Ventas`
- `gold.predicciones_ventas` -> `Predicciones`
- `gold.riesgo_stock` -> `Stock`
- `gold.calidad_datos` -> `Calidad`
- `gold.resumen_mensual` -> `ResumenMensual`
- `gold.rentabilidad_producto` -> `Producto`
- `gold.margen_canal` -> `Canal`

## Ventas y margen

```DAX
Ventas Netas = SUM(Ventas[ventas_netas])

Costes Totales = SUM(Ventas[costes_totales])

Margen = SUM(Ventas[margen])

Margen % = DIVIDE([Margen], [Ventas Netas])

Pedidos = DISTINCTCOUNT(Ventas[id_pedido])

Lineas Venta = COUNTROWS(Ventas)

Unidades = SUM(Ventas[unidades_vendidas])

Ticket Medio = DIVIDE([Ventas Netas], [Pedidos])

Coste % Ventas = DIVIDE([Costes Totales], [Ventas Netas])
```

## Costes

```DAX
Coste Producto = SUM(Ventas[coste_producto])

Comisiones = SUM(Ventas[comision])

Comisiones % = DIVIDE([Comisiones], [Ventas Netas])

Coste Pago = SUM(Ventas[coste_pago])

Coste Envio = SUM(Ventas[coste_envio_asignado])

Descuentos = SUM(Ventas[importe_descuento])

Descuento % Bruto =
DIVIDE(
    [Descuentos],
    SUMX(Ventas, Ventas[unidades_vendidas] * Ventas[precio_unitario_bruto])
)
```

## Alertas de rentabilidad

```DAX
Lineas Margen Negativo = SUM(Ventas[flag_margen_negativo])

Lineas Margen Bajo = SUM(Ventas[flag_margen_bajo])

% Lineas Margen Negativo =
DIVIDE([Lineas Margen Negativo], [Lineas Venta])

% Lineas Margen Bajo =
DIVIDE([Lineas Margen Bajo], [Lineas Venta])
```

## Prediccion

```DAX
Prediccion Unidades = SUM(Predicciones[prediccion_unidades])

Real Unidades Prediccion = SUM(Predicciones[real_unidades])

Error Prediccion = SUM(Predicciones[error_unidades])

Error Absoluto Medio = AVERAGE(Predicciones[error_abs_unidades])

RMSE Prediccion =
SQRT(
    AVERAGEX(
        Predicciones,
        POWER(Predicciones[error_unidades], 2)
    )
)

MAPE Prediccion =
AVERAGEX(
    FILTER(Predicciones, Predicciones[real_unidades] <> 0),
    ABS(DIVIDE(Predicciones[error_unidades], Predicciones[real_unidades]))
)
```

## Stock

```DAX
Productos Almacen = COUNTROWS(Stock)

Stock Riesgo Alto =
CALCULATE(
    COUNTROWS(Stock),
    Stock[nivel_riesgo_stock] = "Riesgo alto"
)

% Stock Riesgo Alto =
DIVIDE([Stock Riesgo Alto], [Productos Almacen])

Stock Disponible = SUM(Stock[stock_disponible])

Stock Reservado = SUM(Stock[stock_reservado])

Unidades Entrantes = SUM(Stock[unidades_entrantes])

Dias Cobertura Medio = AVERAGE(Stock[dias_cobertura_stock])
```

