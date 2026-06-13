# Informe de verificacion del entregable

Fecha: 2026-06-13 20:59:25

## Resultado general

OK: el entregable contiene todos los componentes necesarios para ejecutar el TFM en otro ordenador.

## Inventario

- SQL: 5 scripts .sql
- Python: 9 archivos .py
- Notebooks: 7 archivos .ipynb
- Outputs CSV: 31 archivos .csv
- Outputs graficos: 14 archivos .png
- Power BI TMDL: 20 archivos .tmdl
- ZIP: 260 entradas
- Entorno virtual incluido: False (debe ser False; se regenera al instalar)

## Comprobaciones obligatorias

- [x] requirements.txt
- [x] 00_EJECUTAR_TODO.ps1
- [x] 02_CREAR_BD_LOCALDB.ps1
- [x] 06_CONFIGURAR_POWERBI_SQL.ps1
- [x] sql\SQLCreacionBD.sql
- [x] sql\SQLIntroduccionDatos.sql
- [x] sql\SQLVistasPowerBI.sql
- [x] sql\SQLMedallion_BronzeSilverGold.sql
- [x] notebooks\02_data_science_estadistica_ml_dl.ipynb
- [x] notebooks\_archivo_separados\03_machine_learning_prediccion.ipynb
- [x] src\modelos_utils.py
- [x] streamlit_app\app.py
- [x] powerbi\TFM_MarginAnalytics_PBIP_LEGACY_REPORT\TFM_MarginAnalytics.pbip
- [x] powerbi\TFM_MarginAnalytics_PBIP_LEGACY_REPORT\TFM_MarginAnalytics.Report\definition.pbir
- [x] powerbi\TFM_MarginAnalytics_PBIP_LEGACY_REPORT\TFM_MarginAnalytics.SemanticModel\definition.pbism
- [x] powerbi\TFM_MarginAnalytics_PBIP_LEGACY_REPORT\TFM_MarginAnalytics.SemanticModel\definition\relationships.tmdl

## Comprobaciones SQL

- [x] SQLCreacionBD.sql: creacion de base de datos, esquemas y tablas
- [x] SQLIntroduccionDatos.sql: carga de datos simulados y 75.000 ventas
- [x] SQLVistasPowerBI.sql: vistas SQL para consumo analitico
- [x] SQLMedallion_BronzeSilverGold.sql: arquitectura medallion y predicciones

## Notebooks y machine learning

- 01_EDA_calidad_datos.ipynb - celdas: 34 - marcas detectadas: machine learning, prediccion
- 02_data_science_estadistica_ml_dl.ipynb - celdas: 57 - marcas detectadas: RandomForest, machine learning, MLPRegressor, LinearRegression, GradientBoosting, prediccion, deep learning
- 03_preview_dashboard_powerbi.ipynb - celdas: 14 - marcas detectadas: prediccion
- _archivo_separados\02_estadistica_negocio.ipynb - celdas: 21 - marcas detectadas: machine learning, prediccion
- _archivo_separados\03_machine_learning_prediccion.ipynb - celdas: 20 - marcas detectadas: RandomForest, machine learning, LinearRegression, GradientBoosting, prediccion
- _archivo_separados\04_deep_learning_opcional.ipynb - celdas: 14 - marcas detectadas: machine learning, MLPRegressor, prediccion, deep learning
- _archivo_separados\05_vista_previa_resultados.ipynb - celdas: 14 - marcas detectadas: prediccion

## Archivos Python incluidos

- scripts\00_check_environment.py
- scripts\02_export_predictions_to_sql.py
- scripts\03_validar_modelo_predictivo.py
- src\conexion_sql.py
- src\eda_utils.py
- src\estadistica_utils.py
- src\modelos_utils.py
- src\visualizacion_utils.py
- streamlit_app\app.py

## Power BI

- Proyecto PBIP incluido en ZIP: True
- SQL incluido en ZIP: True
- Componentes incluidos: Report definition PBIR, SemanticModel PBISM, tablas TMDL, relationships.tmdl, report.json y paginas/visuales JSON.

## Ejecucion en otro ordenador

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\00_EJECUTAR_TODO.ps1
```

Si se usa otra instancia SQL:

```powershell
.\00_EJECUTAR_TODO.ps1 -SqlServer ".\SQL_ESTUDIO"
```
