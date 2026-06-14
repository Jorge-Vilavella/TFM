:ON ERROR EXIT

/*
Ejecutar con SQLCMD Mode activado en SQL Server Management Studio.

Orden:
1. Creacion de base de datos y tablas.
2. Insercion de datos simulados.
3. Vistas de apoyo para Power BI.
4. Capas bronze, silver y gold.
*/

:r .\SQLCreacionBD.sql
:r .\SQLIntroduccionDatos.sql
:r .\SQLVistasPowerBI.sql
:r .\SQLMedallion_BronzeSilverGold.sql

PRINT 'Ejecucion completa del proyecto TFM_MarginAnalytics.';
