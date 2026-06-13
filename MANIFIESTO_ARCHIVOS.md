# Manifiesto del paquete

Contenido principal del paquete definitivo:

- `README_EJECUCION.md`: guia para ejecutar todo en otro ordenador.
- `00_VERIFICAR_REQUISITOS.ps1`: comprueba Python, SQL LocalDB, sqlcmd y Power BI.
- `01_CREAR_ENTORNO_PYTHON.ps1`: crea `.venv` e instala dependencias.
- `02_CREAR_BD_LOCALDB.ps1`: ejecuta los SQL contra `(localdb)\MSSQLLocalDB`.
- `03_VALIDAR_MODELO.ps1`: ejecuta la validacion del modelo predictivo.
- `04_ABRIR_POWERBI.ps1`: abre el proyecto PBIP.
- `sql`: creacion de base de datos, insercion de datos, vistas Power BI y medallion.
- `notebooks`: EDA, data science y preview.
- `src`: funciones Python reutilizables.
- `scripts`: ejecuciones Python fuera de notebook.
- `outputs`: datos y graficos generados.
- `documentacion`: logica de negocio, metodologia y validacion.
- `powerbi`: proyecto PBIP y documentacion DAX/Power Query.

No se incluyen entornos virtuales, caches, backups rotos ni carpetas experimentales de Power BI.
