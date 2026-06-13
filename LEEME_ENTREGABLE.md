# TFM Margin Analytics - Entregable ejecutable

Este paquete contiene todo lo necesario para ejecutar el TFM en otro ordenador Windows.

## Requisitos previos

1. Windows 10/11.
2. Python 3.10 o superior instalado y añadido al PATH.
3. SQL Server local con autenticacion Windows. Recomendado: LocalDB `(localdb)\MSSQLLocalDB` o una instancia como `.\SQL_ESTUDIO`.
4. Herramienta `sqlcmd` instalada.
5. Power BI Desktop instalado.

## Ejecucion rapida

Abre PowerShell en esta carpeta y ejecuta:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\00_EJECUTAR_TODO.ps1
```

Por defecto usa LocalDB: `(localdb)\MSSQLLocalDB`.

Si el ordenador destino usa otra instancia SQL Server, ejecuta por ejemplo:

```powershell
.\00_EJECUTAR_TODO.ps1 -SqlServer ".\SQL_ESTUDIO"
```

El script hace lo siguiente:

1. Comprueba requisitos basicos.
2. Crea el entorno Python `.venv`.
3. Instala dependencias desde `requirements.txt`.
4. Crea y carga la base de datos `TFM_MarginAnalytics` con 75.000 lineas de venta.
5. Actualiza el modelo Power BI para conectar al mismo servidor SQL.
6. Abre el informe Power BI.

## Archivos principales

- `sql\`: creacion de base de datos, carga de datos y vistas gold.
- `notebooks\`: analisis EDA, modelos predictivos y previews.
- `powerbi\`: informe Power BI PBIP listo para abrir.
- `outputs\`: graficos y CSV generados.
- `documentacion\`: metodologia, logica de negocio y validacion.
- `streamlit_app\`: app alternativa en Streamlit.

## Apertura manual

Si prefieres ejecutar paso a paso:

```powershell
.\00_VERIFICAR_REQUISITOS.ps1
.\01_CREAR_ENTORNO_PYTHON.ps1
.\02_CREAR_BD_LOCALDB.ps1 -SqlServer "(localdb)\MSSQLLocalDB"
.\06_CONFIGURAR_POWERBI_SQL.ps1 -SqlServer "(localdb)\MSSQLLocalDB"
.\03_VALIDAR_MODELO.ps1
.\04_ABRIR_POWERBI.ps1
```

## Nota importante

No se incluye la carpeta `.venv` porque se regenera automaticamente. Esto reduce el tamano del entregable y evita problemas al moverlo a otro ordenador.
