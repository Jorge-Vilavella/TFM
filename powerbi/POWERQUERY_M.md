# Power Query M

Puedes cargar las tablas desde Power BI con Obtener datos > SQL Server.

Si prefieres usar consultas M, crea consultas en blanco y pega cada bloque.

## Ventas

```powerquery
let
    Source = Sql.Database("(localdb)\MSSQLLocalDB", "TFM_MarginAnalytics", [Query="SELECT * FROM gold.ventas_powerbi"])
in
    Source
```

## Resumen mensual

```powerquery
let
    Source = Sql.Database("(localdb)\MSSQLLocalDB", "TFM_MarginAnalytics", [Query="SELECT * FROM gold.resumen_mensual"])
in
    Source
```

## Canal

```powerquery
let
    Source = Sql.Database("(localdb)\MSSQLLocalDB", "TFM_MarginAnalytics", [Query="SELECT * FROM gold.margen_canal"])
in
    Source
```

## Producto

```powerquery
let
    Source = Sql.Database("(localdb)\MSSQLLocalDB", "TFM_MarginAnalytics", [Query="SELECT * FROM gold.rentabilidad_producto"])
in
    Source
```

## Stock

```powerquery
let
    Source = Sql.Database("(localdb)\MSSQLLocalDB", "TFM_MarginAnalytics", [Query="SELECT * FROM gold.riesgo_stock"])
in
    Source
```

## Predicciones

```powerquery
let
    Source = Sql.Database("(localdb)\MSSQLLocalDB", "TFM_MarginAnalytics", [Query="SELECT * FROM gold.predicciones_ventas"])
in
    Source
```

## Calidad

```powerquery
let
    Source = Sql.Database("(localdb)\MSSQLLocalDB", "TFM_MarginAnalytics", [Query="SELECT * FROM gold.calidad_datos"])
in
    Source
```

