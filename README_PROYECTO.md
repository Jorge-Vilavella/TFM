# TFM Margin Analytics

Proyecto local de analitica y Data Science para analizar margen real en ecommerce y marketplaces.

La estructura esta pensada como se trabajaria en un proyecto profesional:

- SQL Server como fuente central y capa de integridad.
- Arquitectura medallion: `bronze`, `silver` y `gold`.
- Jupyter para EDA, estadistica, modelado y explicacion reproducible.
- Codigo reutilizable en `src/`.
- Configuracion separada en `config/`.
- Salidas separadas en `outputs/`.
- Documentacion de metodologia y logica de negocio en `documentacion/`.

## Objetivo de negocio

Responder a una pregunta principal:

> Que productos, canales y categorias son realmente rentables cuando se incluyen costes de producto, comisiones, descuentos, pagos, envio e inventario?

Ademas, se anade una capa predictiva para anticipar ventas y ayudar a decisiones de stock, promociones y planificacion comercial.

## Estructura

```text
TFM_MarginAnalytics_Jupyter/
|-- config/
|   `-- settings.example.json
|-- documentacion/
|   |-- LOGICA_NEGOCIO_DATA_SCIENCE.md
|   `-- METODOLOGIA_EMPRESARIAL.md
|-- notebooks/
|   |-- 01_EDA_calidad_datos.ipynb
|   |-- 02_data_science_estadistica_ml_dl.ipynb
|   |-- 03_preview_dashboard_powerbi.ipynb
|   `-- _archivo_separados/
|-- outputs/
|   |-- datos/
|   |-- graficos/
|   |-- informes_calidad/
|   |-- modelos/
|   `-- powerbi/
|-- scripts/
|   `-- 00_check_environment.py
|-- sql/
|   |-- SQLCreacionBD.sql
|   |-- SQLIntroduccionDatos.sql
|   |-- SQLMedallion_BronzeSilverGold.sql
|   `-- SQLVistasPowerBI.sql
|-- src/
|   |-- conexion_sql.py
|   |-- eda_utils.py
|   |-- estadistica_utils.py
|   |-- modelos_utils.py
|   `-- visualizacion_utils.py
|-- README.md
`-- requirements.txt
```

## Orden de trabajo

0. `sql/SQLMedallion_BronzeSilverGold.sql`  
   Crea las capas `bronze`, `silver` y `gold` sobre la base SQL local.

1. `01_EDA_calidad_datos.ipynb`  
   Validacion de datos, calidad, primeras metricas y coherencia de negocio.

2. `02_data_science_estadistica_ml_dl.ipynb`  
   Estadistica de negocio, prediccion con machine learning y comparacion opcional con deep learning.

3. `03_preview_dashboard_powerbi.ipynb`  
   Vista previa visual para definir la historia que despues se montara en Power BI.

4. `scripts/03_validar_modelo_predictivo.py`  
   Cierra la validacion del modelo: baseline, WMAPE, sesgo, mejora y documentacion para memoria.

5. `scripts/02_export_predictions_to_sql.py`  
   Exporta la mejor prediccion de Python a `gold.fact_prediccion_ventas`, para que Power BI pueda leerla desde SQL.

## Conexion esperada

Base local:

- Servidor: `(localdb)\MSSQLLocalDB`
- Base de datos: `TFM_MarginAnalytics`

Se puede sobrescribir con variables de entorno:

```powershell
$env:TFM_SQL_SERVER="(localdb)\MSSQLLocalDB"
$env:TFM_SQL_DATABASE="TFM_MarginAnalytics"
```

## Preparar entorno

Desde esta carpeta:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python scripts\00_check_environment.py
jupyter lab
```

## Criterio profesional usado

- Los notebooks cuentan una historia, no son pruebas sueltas.
- El codigo repetible vive en `src/`.
- Los SQL quedan separados de Python.
- `bronze` representa la capa base/raw, `silver` la capa limpia/preparada y `gold` la capa de consumo.
- Las salidas generadas no se mezclan con codigo.
- El deep learning se usa solo como comparacion, no como decoracion tecnica.
- El resultado final se orienta a Power BI y a toma de decisiones.

## Validacion predictiva

Ejecutar `scripts/03_validar_modelo_predictivo.py` despues del notebook 02 para generar los CSVs y la documentacion de validacion del modelo.
