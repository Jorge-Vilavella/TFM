# Guia de construccion del informe en Power BI Desktop

## 1. Abrir Power BI Desktop

No hace falta iniciar sesion si vas a trabajar y presentar desde tu ordenador.

## 2. Conectar a SQL Server local

Ruta:

```text
Inicio > Obtener datos > SQL Server
```

Valores:

```text
Servidor: (localdb)\MSSQLLocalDB
Base de datos: TFM_MarginAnalytics
Modo: Importar
```

Seleccionar principalmente:

```text
gold.ventas_powerbi
gold.resumen_mensual
gold.margen_canal
gold.rentabilidad_producto
gold.riesgo_stock
gold.predicciones_ventas
gold.calidad_datos
```

## 3. Renombrar tablas

Recomendado:

```text
gold.ventas_powerbi          -> Ventas
gold.resumen_mensual         -> ResumenMensual
gold.margen_canal            -> Canal
gold.rentabilidad_producto   -> Producto
gold.riesgo_stock            -> Stock
gold.predicciones_ventas     -> Predicciones
gold.calidad_datos           -> Calidad
```

## 4. Crear medidas

Copiar las medidas de:

```text
powerbi/MEDIDAS_DAX.md
```

## 5. Importar tema

Ruta:

```text
Vista > Temas > Examinar temas
```

Seleccionar:

```text
powerbi/TEMA_TFM_MARGIN_ANALYTICS.json
```

## 6. Crear paginas

Crear estas paginas:

```text
1. Resumen ejecutivo
2. Rentabilidad
3. Prediccion ventas
4. Stock
```

Seguir estructura de:

```text
powerbi/PAGINAS_INFORME.md
```

## 7. Guardar archivo

Guardar como:

```text
E:\TFM_MarginAnalytics_Jupyter_20260518\powerbi\TFM_MarginAnalytics.pbix
```

## 8. Recomendacion final

Cuando el informe este creado, guardar tambien una version PBIP si tu Power BI Desktop lo permite:

```text
Archivo > Guardar como > Power BI project files (*.pbip)
```

Esto deja el informe en formato mas profesional y versionable.

