/*
======================================================================
 TFM_MarginAnalytics - Arquitectura Medallion
 Capas:
   - bronze: capa base/raw sobre las tablas actuales
   - silver: capa limpia/preparada para analisis
   - gold: capa final de consumo para Power BI

 Nota:
   Este script NO elimina ni renombra las tablas dbo existentes.
   Crea schemas, vistas y una tabla de predicciones para integrar Python.
======================================================================
*/

USE TFM_MarginAnalytics;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
    EXEC('CREATE SCHEMA bronze');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold');
GO

/* =========================================================
   BRONZE - Vistas 1:1 sobre tablas base actuales
========================================================= */

CREATE OR ALTER VIEW bronze.dim_fecha AS SELECT * FROM dbo.dim_fecha;
GO
CREATE OR ALTER VIEW bronze.dim_categoria AS SELECT * FROM dbo.dim_categoria;
GO
CREATE OR ALTER VIEW bronze.dim_marca AS SELECT * FROM dbo.dim_marca;
GO
CREATE OR ALTER VIEW bronze.dim_proveedor AS SELECT * FROM dbo.dim_proveedor;
GO
CREATE OR ALTER VIEW bronze.dim_canal AS SELECT * FROM dbo.dim_canal;
GO
CREATE OR ALTER VIEW bronze.dim_cliente AS SELECT * FROM dbo.dim_cliente;
GO
CREATE OR ALTER VIEW bronze.dim_promocion AS SELECT * FROM dbo.dim_promocion;
GO
CREATE OR ALTER VIEW bronze.dim_metodo_pago AS SELECT * FROM dbo.dim_metodo_pago;
GO
CREATE OR ALTER VIEW bronze.dim_envio AS SELECT * FROM dbo.dim_envio;
GO
CREATE OR ALTER VIEW bronze.dim_almacen AS SELECT * FROM dbo.dim_almacen;
GO
CREATE OR ALTER VIEW bronze.dim_producto AS SELECT * FROM dbo.dim_producto;
GO
CREATE OR ALTER VIEW bronze.fact_ventas AS SELECT * FROM dbo.fact_ventas;
GO
CREATE OR ALTER VIEW bronze.fact_inventario AS SELECT * FROM dbo.fact_inventario;
GO

/* =========================================================
   SILVER - Datos limpios, enriquecidos y con reglas de calidad
========================================================= */

CREATE OR ALTER VIEW silver.ventas_limpias
AS
SELECT
    v.*,
    CAST(v.unidades_vendidas * v.precio_unitario_bruto AS DECIMAL(18,2)) AS importe_bruto,
    CASE
        WHEN v.unidades_vendidas * v.precio_unitario_bruto = 0 THEN NULL
        ELSE CAST(v.importe_descuento AS DECIMAL(18,4))
             / NULLIF(CAST(v.unidades_vendidas * v.precio_unitario_bruto AS DECIMAL(18,4)), 0)
    END AS descuento_pct_real,
    CASE WHEN v.margen < 0 THEN 1 ELSE 0 END AS flag_margen_negativo,
    CASE WHEN v.margen_pct < 0.10 THEN 1 ELSE 0 END AS flag_margen_bajo,
    CASE
        WHEN v.importe_descuento > v.unidades_vendidas * v.precio_unitario_bruto THEN 1
        ELSE 0
    END AS flag_descuento_superior_bruto,
    CASE
        WHEN v.unidades_vendidas <= 0 THEN 0
        WHEN v.ventas_netas < 0 THEN 0
        WHEN v.costes_totales < 0 THEN 0
        WHEN v.importe_descuento < 0 THEN 0
        WHEN v.importe_descuento > v.unidades_vendidas * v.precio_unitario_bruto THEN 0
        ELSE 1
    END AS flag_registro_valido
FROM dbo.vw_ventas_enriquecidas v;
GO

CREATE OR ALTER VIEW silver.inventario_limpio
AS
SELECT
    s.*,
    CASE WHEN s.nivel_riesgo_stock = 'Riesgo alto' THEN 1 ELSE 0 END AS flag_riesgo_alto,
    CASE
        WHEN s.dias_cobertura_stock IS NULL THEN 'Sin ventas recientes'
        WHEN s.dias_cobertura_stock < 14 THEN 'Cobertura baja'
        WHEN s.dias_cobertura_stock < 30 THEN 'Cobertura media'
        ELSE 'Cobertura suficiente'
    END AS estado_cobertura_stock
FROM dbo.vw_riesgo_stock s;
GO

CREATE OR ALTER VIEW silver.prediccion_base_ventas
AS
WITH ventas_diarias AS
(
    SELECT
        d.full_date AS fecha,
        d.[year] AS anio,
        d.[month] AS mes_numero,
        d.day_of_week AS dia_semana,
        d.is_weekend AS es_fin_de_semana,
        ch.channel_name AS canal,
        c.category_name AS categoria,
        SUM(fs.units_sold) AS unidades_vendidas,
        SUM(fs.net_sales_amount) AS ventas_netas,
        SUM(fs.margin_amount) AS margen_total
    FROM bronze.fact_ventas fs
    INNER JOIN bronze.dim_fecha d ON fs.date_id = d.date_id
    INNER JOIN bronze.dim_canal ch ON fs.channel_id = ch.channel_id
    INNER JOIN bronze.dim_producto p ON fs.product_id = p.product_id
    INNER JOIN bronze.dim_categoria c ON p.category_id = c.category_id
    GROUP BY
        d.full_date,
        d.[year],
        d.[month],
        d.day_of_week,
        d.is_weekend,
        ch.channel_name,
        c.category_name
),
medias AS
(
    SELECT
        *,
        AVG(CAST(unidades_vendidas AS DECIMAL(18,4))) OVER
        (
            PARTITION BY canal, categoria
            ORDER BY fecha
            ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
        ) AS media_movil_7d_unidades,
        AVG(CAST(unidades_vendidas AS DECIMAL(18,4))) OVER
        (
            PARTITION BY canal, categoria
            ORDER BY fecha
            ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
        ) AS media_movil_30d_unidades
    FROM ventas_diarias
)
SELECT
    fecha,
    anio,
    mes_numero,
    dia_semana,
    es_fin_de_semana,
    canal,
    categoria,
    unidades_vendidas,
    ventas_netas,
    margen_total,
    media_movil_7d_unidades,
    media_movil_30d_unidades,
    media_movil_7d_unidades AS prediccion_naive_proximo_dia,
    CASE
        WHEN media_movil_30d_unidades IS NULL OR media_movil_30d_unidades = 0 THEN 'Sin historico'
        WHEN media_movil_7d_unidades > media_movil_30d_unidades * 1.10 THEN 'Tendencia creciente'
        WHEN media_movil_7d_unidades < media_movil_30d_unidades * 0.90 THEN 'Tendencia decreciente'
        ELSE 'Tendencia estable'
    END AS tendencia_ventas
FROM medias;
GO

CREATE OR ALTER VIEW silver.calidad_datos
AS
SELECT 'ventas_netas_negativas' AS control, COUNT_BIG(*) AS resultado
FROM silver.ventas_limpias
WHERE ventas_netas < 0
UNION ALL
SELECT 'costes_totales_negativos', COUNT_BIG(*)
FROM silver.ventas_limpias
WHERE costes_totales < 0
UNION ALL
SELECT 'unidades_no_positivas', COUNT_BIG(*)
FROM silver.ventas_limpias
WHERE unidades_vendidas <= 0
UNION ALL
SELECT 'descuento_negativo', COUNT_BIG(*)
FROM silver.ventas_limpias
WHERE importe_descuento < 0
UNION ALL
SELECT 'descuento_superior_a_bruto', COUNT_BIG(*)
FROM silver.ventas_limpias
WHERE flag_descuento_superior_bruto = 1
UNION ALL
SELECT 'lineas_margen_negativo', COUNT_BIG(*)
FROM silver.ventas_limpias
WHERE flag_margen_negativo = 1
UNION ALL
SELECT 'registros_invalidos', COUNT_BIG(*)
FROM silver.ventas_limpias
WHERE flag_registro_valido = 0;
GO

/* =========================================================
   GOLD - Capa final para reporting / Power BI
========================================================= */

CREATE OR ALTER VIEW gold.ventas_powerbi
AS
SELECT *
FROM silver.ventas_limpias
WHERE flag_registro_valido = 1;
GO

CREATE OR ALTER VIEW gold.resumen_ejecutivo
AS
SELECT
    COUNT(DISTINCT id_pedido) AS pedidos,
    COUNT(*) AS lineas_venta,
    SUM(unidades_vendidas) AS unidades_vendidas,
    SUM(ventas_netas) AS ventas_netas,
    SUM(costes_totales) AS costes_totales,
    SUM(margen) AS margen,
    CASE WHEN SUM(ventas_netas) = 0 THEN NULL ELSE SUM(margen) / SUM(ventas_netas) END AS margen_pct,
    SUM(flag_margen_negativo) AS lineas_margen_negativo
FROM gold.ventas_powerbi;
GO

CREATE OR ALTER VIEW gold.margen_canal
AS
SELECT
    canal,
    tipo_canal,
    COUNT(DISTINCT id_pedido) AS pedidos,
    SUM(unidades_vendidas) AS unidades_vendidas,
    SUM(ventas_netas) AS ventas_netas,
    SUM(costes_totales) AS costes_totales,
    SUM(margen) AS margen,
    CASE WHEN SUM(ventas_netas) = 0 THEN NULL ELSE SUM(margen) / SUM(ventas_netas) END AS margen_pct,
    SUM(comision) AS comisiones,
    SUM(coste_pago) AS costes_pago,
    SUM(coste_envio_asignado) AS costes_envio,
    SUM(flag_margen_negativo) AS lineas_margen_negativo
FROM gold.ventas_powerbi
GROUP BY canal, tipo_canal;
GO

CREATE OR ALTER VIEW gold.rentabilidad_producto
AS
SELECT
    id_producto,
    codigo_producto,
    sku,
    producto,
    categoria,
    subcategoria,
    marca,
    proveedor,
    COUNT(*) AS lineas_venta,
    COUNT(DISTINCT id_pedido) AS pedidos,
    SUM(unidades_vendidas) AS unidades_vendidas,
    SUM(ventas_netas) AS ventas_netas,
    SUM(costes_totales) AS costes_totales,
    SUM(margen) AS margen,
    CASE WHEN SUM(ventas_netas) = 0 THEN NULL ELSE SUM(margen) / SUM(ventas_netas) END AS margen_pct,
    RANK() OVER (ORDER BY SUM(margen) DESC) AS ranking_margen
FROM gold.ventas_powerbi
GROUP BY
    id_producto,
    codigo_producto,
    sku,
    producto,
    categoria,
    subcategoria,
    marca,
    proveedor;
GO

CREATE OR ALTER VIEW gold.resumen_mensual
AS
SELECT
    anio,
    mes_numero,
    mes_nombre,
    canal,
    tipo_canal,
    categoria,
    COUNT(*) AS lineas_venta,
    COUNT(DISTINCT id_pedido) AS pedidos,
    SUM(unidades_vendidas) AS unidades_vendidas,
    SUM(ventas_netas) AS ventas_netas,
    SUM(costes_totales) AS costes_totales,
    SUM(margen) AS margen,
    CASE WHEN SUM(ventas_netas) = 0 THEN NULL ELSE SUM(margen) / SUM(ventas_netas) END AS margen_pct,
    SUM(flag_margen_negativo) AS lineas_margen_negativo
FROM gold.ventas_powerbi
GROUP BY
    anio,
    mes_numero,
    mes_nombre,
    canal,
    tipo_canal,
    categoria;
GO

CREATE OR ALTER VIEW gold.riesgo_stock
AS
SELECT *
FROM silver.inventario_limpio;
GO

CREATE OR ALTER VIEW gold.calidad_datos
AS
SELECT *
FROM silver.calidad_datos;
GO

CREATE OR ALTER VIEW gold.prediccion_base_ventas
AS
SELECT *
FROM silver.prediccion_base_ventas;
GO

IF OBJECT_ID('gold.fact_prediccion_ventas', 'U') IS NULL
BEGIN
    CREATE TABLE gold.fact_prediccion_ventas
    (
        id_prediccion          BIGINT IDENTITY(1,1) NOT NULL,
        fecha                  DATE NOT NULL,
        canal                  VARCHAR(100) NOT NULL,
        categoria              VARCHAR(100) NOT NULL,
        modelo                 VARCHAR(150) NOT NULL,
        real_unidades          DECIMAL(18,4) NULL,
        prediccion_unidades    DECIMAL(18,4) NOT NULL,
        error_unidades         DECIMAL(18,4) NULL,
        error_abs_unidades     DECIMAL(18,4) NULL,
        fecha_ejecucion        DATETIME2 NOT NULL DEFAULT(SYSDATETIME()),
        CONSTRAINT PK_gold_fact_prediccion_ventas PRIMARY KEY (id_prediccion)
    );
END;
GO

CREATE OR ALTER VIEW gold.predicciones_ventas
AS
SELECT
    id_prediccion,
    fecha,
    canal,
    categoria,
    modelo,
    real_unidades,
    prediccion_unidades,
    error_unidades,
    error_abs_unidades,
    fecha_ejecucion
FROM gold.fact_prediccion_ventas
WHERE modelo = 'Random Forest';
GO

PRINT 'Arquitectura medallion bronze/silver/gold creada correctamente.';
GO

