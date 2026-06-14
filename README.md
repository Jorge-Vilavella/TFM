# TFM Margin Analytics

Proyecto de analitica de rentabilidad para un negocio e-commerce multicanal. El trabajo integra modelado SQL, analisis con Python, modelos predictivos y un informe final en Power BI.

## Contenido

- `sql/`: scripts de creacion de base de datos, carga de datos, vistas analiticas y capa medallion.
- `src/`: funciones Python de conexion, analisis, estadistica, modelado y visualizacion.
- `notebooks/`: analisis exploratorio, estadistica, machine learning, deep learning y vista previa de resultados.
- `powerbi/`: proyecto Power BI con modelo semantico, relaciones, medidas y paginas del informe.
- `outputs/`: resultados generados, CSV, graficos e informes de calidad.
- `documentacion/`: explicacion metodologica, logica de negocio y validacion del modelo predictivo.
- `streamlit_app/`: aplicacion alternativa para visualizacion rapida.
- `config/` y `scripts/`: configuracion y utilidades de apoyo.

## Requisitos

- Python 3.10 o superior.
- SQL Server local o LocalDB.
- `sqlcmd` disponible en consola.
- Power BI Desktop.

Instalar dependencias Python:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install jupyterlab seaborn statsmodels nbformat nbclient ipykernel streamlit
```

## Ejecucion SQL

Ejecutar los scripts de la carpeta `sql/` en este orden sobre la base de datos local:

1. `SQLCreacionBD.sql`
2. `SQLIntroduccionDatos.sql`
3. `SQLVistasPowerBI.sql`
4. `SQLMedallion_BronzeSilverGold.sql`

El script de carga genera un conjunto de datos simulado con 75.000 lineas de venta.

Ejemplo con `sqlcmd` y LocalDB:

```powershell
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -i "sql\SQLCreacionBD.sql" -b
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -i "sql\SQLIntroduccionDatos.sql" -b
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -i "sql\SQLVistasPowerBI.sql" -b
sqlcmd -S "(localdb)\MSSQLLocalDB" -E -i "sql\SQLMedallion_BronzeSilverGold.sql" -b
```

Si se usa otra instancia, sustituir `(localdb)\MSSQLLocalDB` por el nombre correspondiente, por ejemplo `.\SQL_ESTUDIO`.

## Notebooks

Los notebooks principales son:

- `notebooks/01_EDA_calidad_datos.ipynb`
- `notebooks/02_data_science_estadistica_ml_dl.ipynb`
- `notebooks/03_preview_dashboard_powerbi.ipynb`

El notebook principal de ciencia de datos incluye modelos de prediccion de ventas y comparacion de resultados.

## Power BI

Abrir el proyecto:

```text
powerbi/TFM_MarginAnalytics_PBIP_LEGACY_REPORT/TFM_MarginAnalytics.pbip
```

Si el servidor SQL del ordenador destino tiene otro nombre, actualizar la conexion en el modelo semantico de Power BI antes de refrescar datos.

## Objetivo del proyecto

El informe permite analizar ventas, margen, rentabilidad por producto, canal y categoria, calidad de datos, stock, reposicion y predicciones de ventas. La finalidad es convertir datos operativos en informacion util para apoyar decisiones de negocio.