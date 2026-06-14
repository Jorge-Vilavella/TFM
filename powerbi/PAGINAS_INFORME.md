# Paginas del informe Power BI

## Pagina 1 - Resumen ejecutivo

Objetivo:

Mostrar la salud general del negocio: ventas, costes, margen y riesgo.

Visuales:

- Tarjeta: `Ventas Netas`
- Tarjeta: `Margen`
- Tarjeta: `Margen %`
- Tarjeta: `Pedidos`
- Tarjeta: `Unidades`
- Tarjeta: `Stock Riesgo Alto`
- Grafico de lineas: `fecha` vs `Ventas Netas` y `Margen`
- Grafico de barras: `canal` vs `Margen %`
- Tabla/matriz: top categorias por margen

Segmentadores:

- `fecha`
- `canal`
- `categoria`
- `tipo_canal`

Mensaje de negocio:

El objetivo no es solo vender mas, sino identificar que ventas dejan margen real.

## Pagina 2 - Rentabilidad por canal y producto

Objetivo:

Comparar venta directa y marketplaces y detectar productos rentables/problematicos.

Visuales:

- Barras: `canal` vs `Ventas Netas`
- Barras: `canal` vs `Margen %`
- Barras apiladas: costes por canal (`Coste Producto`, `Comisiones`, `Coste Pago`, `Coste Envio`)
- Matriz: producto, categoria, canal, ventas, margen, margen %
- Scatter: `Ventas Netas` vs `Margen %`, leyenda por `canal`
- Tabla: productos con `Lineas Margen Negativo` o margen bajo

Mensaje de negocio:

Un canal con mucho volumen puede no ser el mas rentable si comisiones y costes reducen el margen.

## Pagina 3 - Prediccion de ventas

Objetivo:

Mostrar la parte predictiva y su utilidad para planificacion.

Visuales:

- Lineas: `fecha`, `Real Unidades Prediccion`, `Prediccion Unidades`
- Tarjeta: `RMSE Prediccion`
- Tarjeta: `Error Absoluto Medio`
- Tarjeta: `MAPE Prediccion`
- Barras: error absoluto por canal
- Tabla: fecha, canal, categoria, real, prediccion, error

Segmentadores:

- `canal`
- `categoria`
- `modelo`

Mensaje de negocio:

La prediccion permite anticipar demanda para planificar stock, promociones y objetivos.

## Pagina 4 - Inventario y riesgo de stock

Objetivo:

Detectar productos con riesgo de rotura o poca cobertura.

Visuales:

- Tarjeta: `Stock Riesgo Alto`
- Tarjeta: `% Stock Riesgo Alto`
- Tarjeta: `Dias Cobertura Medio`
- Barras: `nivel_riesgo_stock` por numero de registros
- Tabla: producto, categoria, almacen, stock disponible, punto reposicion, dias cobertura, nivel riesgo
- Barras: productos con menor cobertura

Mensaje de negocio:

El margen no sirve de mucho si se pierde venta por falta de stock en productos con demanda.

