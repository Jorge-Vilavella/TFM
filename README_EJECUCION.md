# TFM Margin Analytics - paquete portable

Este paquete contiene lo necesario para reconstruir y ejecutar el proyecto en otro ordenador:

- Base de datos local en SQL Server LocalDB.
- Scripts SQL de creacion, carga de datos, vistas y capas bronze/silver/gold.
- Notebooks de EDA, data science, validacion del modelo predictivo y preview.
- Codigo Python reutilizable.
- Salidas ya generadas para revisar resultados.
- Proyecto Power BI en formato PBIP.
- Documentacion de negocio, metodologia y validacion.

## Requisitos del otro ordenador

Instala antes de ejecutar:

1. SQL Server LocalDB o SQL Server Express con LocalDB.
2. SQL Server Management Studio, recomendado para ejecutar SQL manualmente.
3. Python 3.10 o superior.
4. Power BI Desktop.
5. ODBC Driver for SQL Server, si Python no conecta con SQL Server.

La base de datos esta pensada para ejecutarse en local, con este servidor:

```text
(localdb)\MSSQLLocalDB
```

Y esta base de datos:

```text
TFM_MarginAnalytics
```

## Ejecucion rapida

Abre PowerShell en esta carpeta y ejecuta:

```powershell
.\00_VERIFICAR_REQUISITOS.ps1
.\01_CREAR_ENTORNO_PYTHON.ps1
.\02_CREAR_BD_LOCALDB.ps1
.\03_VALIDAR_MODELO.ps1
.\04_ABRIR_POWERBI.ps1
```

Si PowerShell bloquea los scripts, ejecuta esta orden solo para la sesion actual:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## Orden SQL manual

Si prefieres hacerlo desde SQL Server Management Studio:

1. Conectate a `(localdb)\MSSQLLocalDB`.
2. Ejecuta `sql\SQLCreacionBD.sql`.
3. Ejecuta `sql\SQLIntroduccionDatos.sql`.
4. Ejecuta `sql\SQLVistasPowerBI.sql`.
5. Ejecuta `sql\SQLMedallion_BronzeSilverGold.sql`.

Tambien puedes abrir `sql\00_EJECUTAR_TODO_EN_ORDEN.sql` en SSMS con SQLCMD Mode activado.

## Notebooks

Despues de crear el entorno Python:

```powershell
.\.venv\Scripts\Activate.ps1
jupyter lab
```

Ejecuta los notebooks en este orden:

1. `notebooks\01_EDA_calidad_datos.ipynb`
2. `notebooks\02_data_science_estadistica_ml_dl.ipynb`
3. `notebooks\03_preview_dashboard_powerbi.ipynb`

## Power BI

Abre:

```text
powerbi\TFM_MarginAnalytics_PBIP_LEGACY_REPORT\TFM_MarginAnalytics.pbip
```

Luego pulsa `Actualizar`.

Si pide credenciales:

- Servidor: `(localdb)\MSSQLLocalDB`
- Base de datos: `TFM_MarginAnalytics`
- Modo: autenticacion de Windows

Si Power BI mantiene credenciales antiguas:

1. Archivo > Opciones y configuracion > Configuracion de origen de datos.
2. Borra permisos del origen SQL anterior.
3. Vuelve a actualizar.

## Comprobacion del modelo predictivo

El script principal de validacion es:

```powershell
python scripts\03_validar_modelo_predictivo.py
```

Genera o actualiza estos archivos:

- `outputs\datos\validacion_modelo_predictivo.csv`
- `outputs\datos\validacion_modelo_por_canal.csv`
- `outputs\datos\validacion_modelo_por_categoria.csv`

Estos resultados sirven para justificar en el TFM que el modelo no solo predice, sino que esta validado con metricas de error.

## Idea de defensa

El proyecto sigue un flujo empresarial:

1. SQL Server local como fuente operativa/analitica.
2. Capas bronze, silver y gold para calidad y gobierno del dato.
3. Python/Jupyter para EDA, estadistica, machine learning y validacion.
4. Power BI para comunicar decisiones de margen, ventas, producto, canal, stock y prediccion.

Esto permite presentar una solucion completa, no solo un dashboard.
