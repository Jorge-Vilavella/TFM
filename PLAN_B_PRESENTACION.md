# Plan B para la presentacion

Este documento existe para no improvisar si algo falla el dia de la defensa.

## Si Power BI abre pero no actualiza

No entres en panico.

1. Explica que el modelo esta en modo Import.
2. Entra en Configuracion de origen de datos.
3. Borra permisos del origen SQL.
4. Vuelve a conectar con:

```text
(localdb)\MSSQLLocalDB
TFM_MarginAnalytics
```

Si sigue fallando, presenta con los datos ya cargados si el informe abre.

## Si Power BI no abre

Usa como respaldo:

```text
powerbi\TFM_MarginAnalytics_informe_preview.html
outputs\graficos
outputs\datos
```

Explicacion:

> Tengo preparado un respaldo en HTML y graficos exportados para explicar los resultados aunque Power BI Desktop tenga un problema local.

## Si SQL LocalDB falla

Prueba:

```powershell
sqllocaldb info
sqllocaldb start MSSQLLocalDB
```

Si no existe la instancia:

```powershell
sqllocaldb create MSSQLLocalDB
sqllocaldb start MSSQLLocalDB
```

Luego ejecuta de nuevo:

```powershell
.\02_CREAR_BD_LOCALDB.ps1
```

Si `sqlcmd` falla, usa SSMS y ejecuta los SQL manualmente.

## Si Python falla

No dependas de ejecutar notebooks en directo.

1. Comprueba que Python esta instalado.
2. Ejecuta:

```powershell
.\01_CREAR_ENTORNO_PYTHON.ps1
```

Si no da tiempo, usa los CSV ya generados en:

```text
outputs\datos
```

Y los graficos ya exportados en:

```text
outputs\graficos
```

## Si Streamlit falla

Se elimina de la demo.

Frase:

> Streamlit era una demo complementaria de la parte predictiva. El producto principal esta en Power BI y el flujo SQL/Python queda documentado y validado.

## Si te preguntan por datos reales

Respuesta:

> No he tenido acceso a datos reales de una empresa. Para no inventar resultados sin control, he creado datos sinteticos con reglas de negocio realistas. La arquitectura esta preparada para sustituir esa fuente por datos reales manteniendo el mismo flujo: SQL, calidad, modelo y dashboard.

## Si te preguntan si el modelo predice bien

Respuesta:

> El modelo se plantea como una primera version de apoyo a decision, no como un sistema automatico. Se ha validado con MAE, RMSE, WMAPE, R2 y sesgo. La utilidad esta en anticipar tendencias y detectar segmentos donde revisar demanda o stock, no en prometer exactitud perfecta.

## Si te preguntan que aporta frente a Excel

Respuesta:

> Excel puede servir para analisis puntual, pero aqui hay un flujo reproducible: base SQL, capas bronze/silver/gold, validacion en Python, metricas predictivas y dashboard conectado. La diferencia es trazabilidad, escalabilidad y capacidad de actualizacion.

