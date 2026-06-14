/*
======================================================================
 TFM - Seed de datos simulados para negocio realista
 Base objetivo: TFM_MarginAnalytics
 Motor objetivo: Microsoft SQL Server

 Proposito:
   - Rellenar la base con datos coherentes para un ecommerce multicanal.
   - Simular ventas en web propia y marketplaces.
   - Generar margenes reales usando las columnas calculadas de fact_ventas.

 IMPORTANTE:
   - Este script NO crea la base. Ejecutarlo despues del script de estructura.
   - No insertes a mano net_sales_amount, total_costs_amount, margin_amount
     ni margin_pct: la base los calcula automaticamente.
   - Si fact_ventas o fact_inventario ya tienen datos, el script se detiene
     para evitar duplicados accidentales.
======================================================================
*/

USE TFM_MarginAnalytics;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET DATEFIRST 1;

DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate DATE = '2025-12-31';
DECLARE @CustomerCount INT = 3000;
DECLARE @ProductCount INT = 500;
DECLARE @SalesLineCount INT = 75000;
DECLARE @MaxNumber INT;

SELECT @MaxNumber =
    (SELECT MAX(v)
     FROM (VALUES (@CustomerCount), (@ProductCount), (@SalesLineCount)) AS x(v));

IF DB_ID('TFM_MarginAnalytics') IS NULL
BEGIN
    THROW 50000, 'La base TFM_MarginAnalytics no existe en esta instancia.', 1;
END;

IF EXISTS (SELECT 1 FROM dbo.fact_ventas) OR EXISTS (SELECT 1 FROM dbo.fact_inventario)
BEGIN
    THROW 50001, 'fact_ventas o fact_inventario ya tienen datos. Vacialas conscientemente antes de resembrar.', 1;
END;

BEGIN TRANSACTION;

IF OBJECT_ID('tempdb..#numbers') IS NOT NULL
BEGIN
    DROP TABLE #numbers;
END;

WITH
e1(n) AS
(
    SELECT 1
    FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) AS d(n)
),
e2(n) AS (SELECT 1 FROM e1 a CROSS JOIN e1 b),
e4(n) AS (SELECT 1 FROM e2 a CROSS JOIN e2 b),
e8(n) AS (SELECT 1 FROM e4 a CROSS JOIN e4 b)
SELECT TOP (@MaxNumber)
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
INTO #numbers
FROM e8;

CREATE UNIQUE CLUSTERED INDEX IX_numbers_n ON #numbers(n);

/* ================================================================
   Dimensiones base
================================================================ */

DECLARE @d DATE = @StartDate;

WHILE @d <= @EndDate
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.dim_fecha WHERE full_date = @d)
    BEGIN
        INSERT INTO dbo.dim_fecha
        (
            date_id,
            full_date,
            [day],
            [month],
            month_name,
            [quarter],
            [year],
            week_of_year,
            day_of_week,
            day_name,
            is_weekend,
            is_month_end,
            is_month_start
        )
        VALUES
        (
            CONVERT(INT, CONVERT(CHAR(8), @d, 112)),
            @d,
            DATEPART(DAY, @d),
            DATEPART(MONTH, @d),
            DATENAME(MONTH, @d),
            DATEPART(QUARTER, @d),
            DATEPART(YEAR, @d),
            DATEPART(ISO_WEEK, @d),
            DATEPART(WEEKDAY, @d),
            DATENAME(WEEKDAY, @d),
            CASE WHEN DATEPART(WEEKDAY, @d) IN (6, 7) THEN 1 ELSE 0 END,
            CASE WHEN @d = EOMONTH(@d) THEN 1 ELSE 0 END,
            CASE WHEN DATEPART(DAY, @d) = 1 THEN 1 ELSE 0 END
        );
    END;

    SET @d = DATEADD(DAY, 1, @d);
END;

INSERT INTO dbo.dim_canal (channel_name, channel_type, default_commission_pct, fulfillment_type, country_scope)
SELECT v.channel_name, v.channel_type, v.default_commission_pct, v.fulfillment_type, v.country_scope
FROM
(
    VALUES
    ('Web Propia', 'Direct', 0.0000, 'Own', 'ES'),
    ('Amazon', 'Marketplace', 0.1500, 'Marketplace', 'ES'),
    ('Miravia', 'Marketplace', 0.1200, 'Marketplace', 'ES'),
    ('Shein', 'Marketplace', 0.1800, 'Marketplace', 'ES')
) AS v(channel_name, channel_type, default_commission_pct, fulfillment_type, country_scope)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.dim_canal dc
    WHERE dc.channel_name = v.channel_name
);

INSERT INTO dbo.dim_metodo_pago (payment_method_name, fee_pct, fee_fixed)
SELECT v.payment_method_name, v.fee_pct, v.fee_fixed
FROM
(
    VALUES
    ('Tarjeta', 0.0125, 0.30),
    ('PayPal', 0.0290, 0.35),
    ('Transferencia', 0.0000, 0.00),
    ('Contra reembolso', 0.0150, 1.50)
) AS v(payment_method_name, fee_pct, fee_fixed)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.dim_metodo_pago pm
    WHERE pm.payment_method_name = v.payment_method_name
);

INSERT INTO dbo.dim_envio (shipment_type, carrier_name, shipping_zone, estimated_shipping_cost, delivery_time_days)
SELECT v.shipment_type, v.carrier_name, v.shipping_zone, v.estimated_shipping_cost, v.delivery_time_days
FROM
(
    VALUES
    ('Standard', 'Correos', 'Nacional', 3.50, 3),
    ('Express', 'SEUR', 'Nacional', 5.95, 1),
    ('Pickup', 'Punto de recogida', 'Nacional', 1.50, 2),
    ('International', 'DHL', 'UE', 8.90, 4)
) AS v(shipment_type, carrier_name, shipping_zone, estimated_shipping_cost, delivery_time_days)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.dim_envio sh
    WHERE sh.shipment_type = v.shipment_type
      AND ISNULL(sh.carrier_name, '') = ISNULL(v.carrier_name, '')
);

INSERT INTO dbo.dim_almacen (warehouse_name, warehouse_region, capacity_level)
SELECT v.warehouse_name, v.warehouse_region, v.capacity_level
FROM
(
    VALUES
    ('Almacen Central', 'Lleida', 'Alta'),
    ('Almacen Secundario', 'Barcelona', 'Media')
) AS v(warehouse_name, warehouse_region, capacity_level)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.dim_almacen w
    WHERE w.warehouse_name = v.warehouse_name
);

INSERT INTO dbo.dim_categoria (category_name, subcategory_name, business_unit)
SELECT v.category_name, v.subcategory_name, v.business_unit
FROM
(
    VALUES
    ('Moda Mujer', 'Vestidos', 'Fashion'),
    ('Moda Mujer', 'Tops', 'Fashion'),
    ('Moda Hombre', 'Camisetas', 'Fashion'),
    ('Moda Hombre', 'Pantalones', 'Fashion'),
    ('Calzado', 'Zapatillas', 'Fashion'),
    ('Calzado', 'Sandalias', 'Fashion'),
    ('Belleza', 'Cosmetica', 'Beauty'),
    ('Belleza', 'Cuidado facial', 'Beauty'),
    ('Accesorios', 'Bolsos', 'Fashion'),
    ('Accesorios', 'Bisuteria', 'Fashion'),
    ('Hogar', 'Decoracion', 'Home'),
    ('Hogar', 'Textil hogar', 'Home'),
    ('Electronica', 'Accesorios movil', 'Tech'),
    ('Deporte', 'Fitness', 'Sports'),
    ('Infantil', 'Ropa infantil', 'Kids'),
    ('Outlet', 'Liquidacion', 'Clearance')
) AS v(category_name, subcategory_name, business_unit)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.dim_categoria c
    WHERE c.category_name = v.category_name
      AND ISNULL(c.subcategory_name, '') = ISNULL(v.subcategory_name, '')
);

INSERT INTO dbo.dim_marca (brand_name, brand_segment, origin_country)
SELECT v.brand_name, v.brand_segment, v.origin_country
FROM
(
    VALUES
    ('NordWear', 'Mid', 'ES'),
    ('Luma Basics', 'Value', 'ES'),
    ('Atelier Nova', 'Premium', 'FR'),
    ('Urban Lane', 'Mid', 'IT'),
    ('Marea Studio', 'Mid', 'ES'),
    ('PureSkin Lab', 'Premium', 'FR'),
    ('Casa Nube', 'Mid', 'PT'),
    ('FitCore', 'Mid', 'DE'),
    ('MiniRoots', 'Value', 'ES'),
    ('Velvet Point', 'Premium', 'IT'),
    ('Daily Motion', 'Value', 'ES'),
    ('Aster Beauty', 'Mid', 'ES'),
    ('Nomad Steps', 'Mid', 'PT'),
    ('Blue Harbor', 'Value', 'ES'),
    ('Siena Goods', 'Premium', 'IT'),
    ('Pixel Mate', 'Mid', 'DE'),
    ('Linen House', 'Mid', 'PT'),
    ('Opal Charm', 'Value', 'ES'),
    ('North Peak', 'Premium', 'DE'),
    ('Soft Bay', 'Value', 'ES')
) AS v(brand_name, brand_segment, origin_country)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.dim_marca b
    WHERE b.brand_name = v.brand_name
);

INSERT INTO dbo.dim_proveedor (supplier_name, supplier_country, lead_time_days, supplier_type)
SELECT v.supplier_name, v.supplier_country, v.lead_time_days, v.supplier_type
FROM
(
    VALUES
    ('Iberia Textile Group', 'ES', 7, 'Manufacturer'),
    ('Mediterranean Imports', 'ES', 12, 'Distributor'),
    ('Porto Home Supplies', 'PT', 10, 'Manufacturer'),
    ('Milano Fashion Partners', 'IT', 14, 'Distributor'),
    ('Lyon Beauty Labs', 'FR', 18, 'Manufacturer'),
    ('Berlin Tech Wholesale', 'DE', 9, 'Distributor'),
    ('Valencia Footwear Co', 'ES', 11, 'Manufacturer'),
    ('Lisbon Kids Factory', 'PT', 15, 'Manufacturer'),
    ('Barcelona Accessories Hub', 'ES', 6, 'Distributor'),
    ('EU Sports Supply', 'DE', 13, 'Distributor'),
    ('Madrid Outlet Center', 'ES', 5, 'Liquidator'),
    ('Nice Premium Goods', 'FR', 20, 'Manufacturer')
) AS v(supplier_name, supplier_country, lead_time_days, supplier_type)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.dim_proveedor s
    WHERE s.supplier_name = v.supplier_name
);

INSERT INTO dbo.dim_promocion (promotion_name, promotion_type, discount_pct, start_date, end_date)
SELECT v.promotion_name, v.promotion_type, v.discount_pct, v.start_date, v.end_date
FROM
(
    VALUES
    ('Rebajas Enero 2024', 'Seasonal', 0.1800, CONVERT(DATE, '2024-01-07'), CONVERT(DATE, '2024-01-31')),
    ('Spring Sale 2024', 'Seasonal', 0.1200, CONVERT(DATE, '2024-04-15'), CONVERT(DATE, '2024-04-28')),
    ('Summer Sale 2024', 'Seasonal', 0.2000, CONVERT(DATE, '2024-07-01'), CONVERT(DATE, '2024-07-31')),
    ('Black Friday 2024', 'Campaign', 0.3000, CONVERT(DATE, '2024-11-22'), CONVERT(DATE, '2024-12-02')),
    ('Christmas Push 2024', 'Campaign', 0.1000, CONVERT(DATE, '2024-12-10'), CONVERT(DATE, '2024-12-24')),
    ('Rebajas Enero 2025', 'Seasonal', 0.1800, CONVERT(DATE, '2025-01-07'), CONVERT(DATE, '2025-01-31')),
    ('Spring Sale 2025', 'Seasonal', 0.1200, CONVERT(DATE, '2025-04-14'), CONVERT(DATE, '2025-04-27')),
    ('Summer Sale 2025', 'Seasonal', 0.2200, CONVERT(DATE, '2025-07-01'), CONVERT(DATE, '2025-07-31')),
    ('Back To School 2025', 'Campaign', 0.1500, CONVERT(DATE, '2025-09-01'), CONVERT(DATE, '2025-09-15')),
    ('Black Friday 2025', 'Campaign', 0.3200, CONVERT(DATE, '2025-11-21'), CONVERT(DATE, '2025-12-01')),
    ('Christmas Push 2025', 'Campaign', 0.1000, CONVERT(DATE, '2025-12-10'), CONVERT(DATE, '2025-12-24'))
) AS v(promotion_name, promotion_type, discount_pct, start_date, end_date)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.dim_promocion p
    WHERE p.promotion_name = v.promotion_name
);

/* ================================================================
   Clientes y productos
================================================================ */

INSERT INTO dbo.dim_cliente
(
    customer_code,
    customer_segment,
    country,
    region,
    city,
    acquisition_channel,
    loyalty_level
)
SELECT
    'CUST' + RIGHT('000000' + CONVERT(VARCHAR(6), n.n), 6),
    CASE
        WHEN r.segment_roll < 45 THEN 'Recurrente'
        WHEN r.segment_roll < 75 THEN 'Nuevo'
        WHEN r.segment_roll < 92 THEN 'Premium'
        ELSE 'Riesgo abandono'
    END,
    'ES',
    CASE r.region_roll
        WHEN 0 THEN 'Catalunya'
        WHEN 1 THEN 'Madrid'
        WHEN 2 THEN 'Comunitat Valenciana'
        WHEN 3 THEN 'Andalucia'
        WHEN 4 THEN 'Aragon'
        WHEN 5 THEN 'Galicia'
        WHEN 6 THEN 'Pais Vasco'
        WHEN 7 THEN 'Castilla y Leon'
        WHEN 8 THEN 'Illes Balears'
        ELSE 'Murcia'
    END,
    CASE r.region_roll
        WHEN 0 THEN 'Barcelona'
        WHEN 1 THEN 'Madrid'
        WHEN 2 THEN 'Valencia'
        WHEN 3 THEN 'Sevilla'
        WHEN 4 THEN 'Zaragoza'
        WHEN 5 THEN 'A Coruna'
        WHEN 6 THEN 'Bilbao'
        WHEN 7 THEN 'Valladolid'
        WHEN 8 THEN 'Palma'
        ELSE 'Murcia'
    END,
    CASE
        WHEN r.acq_roll < 35 THEN 'Organic'
        WHEN r.acq_roll < 60 THEN 'Paid Social'
        WHEN r.acq_roll < 78 THEN 'Marketplace'
        WHEN r.acq_roll < 92 THEN 'Email'
        ELSE 'Referral'
    END,
    CASE
        WHEN r.loyalty_roll < 55 THEN 'Bronze'
        WHEN r.loyalty_roll < 82 THEN 'Silver'
        WHEN r.loyalty_roll < 96 THEN 'Gold'
        ELSE 'Platinum'
    END
FROM #numbers n
CROSS APPLY
(
    SELECT
        ABS(CHECKSUM(NEWID()) % 100) AS segment_roll,
        ABS(CHECKSUM(NEWID()) % 10) AS region_roll,
        ABS(CHECKSUM(NEWID()) % 100) AS acq_roll,
        ABS(CHECKSUM(NEWID()) % 100) AS loyalty_roll
) r
WHERE n.n <= @CustomerCount
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.dim_cliente c
      WHERE c.customer_code = 'CUST' + RIGHT('000000' + CONVERT(VARCHAR(6), n.n), 6)
  );

INSERT INTO dbo.dim_producto
(
    product_code,
    product_name,
    sku,
    category_id,
    brand_id,
    supplier_id,
    launch_date,
    standard_cost,
    standard_price
)
SELECT
    'PROD' + RIGHT('000000' + CONVERT(VARCHAR(6), n.n), 6),
    c.category_name + ' ' + ISNULL(c.subcategory_name, 'General') + ' ' + RIGHT('0000' + CONVERT(VARCHAR(4), n.n), 4),
    'SKU-' + RIGHT('000000' + CONVERT(VARCHAR(6), n.n), 6),
    c.category_id,
    b.brand_id,
    s.supplier_id,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 720), @StartDate),
    price.standard_cost,
    price.standard_price
FROM #numbers n
CROSS APPLY
(
    SELECT TOP (1)
        category_id,
        category_name,
        subcategory_name,
        business_unit
    FROM dbo.dim_categoria
    ORDER BY CHECKSUM(NEWID(), n.n)
) c
CROSS APPLY
(
    SELECT TOP (1)
        brand_id,
        brand_segment
    FROM dbo.dim_marca
    ORDER BY CHECKSUM(NEWID(), n.n)
) b
CROSS APPLY
(
    SELECT TOP (1)
        supplier_id
    FROM dbo.dim_proveedor
    ORDER BY CHECKSUM(NEWID(), n.n)
) s
CROSS APPLY
(
    SELECT
        CAST
        (
            CASE c.business_unit
                WHEN 'Tech' THEN 8.00 + (ABS(CHECKSUM(NEWID()) % 7000) / 100.0)
                WHEN 'Beauty' THEN 3.00 + (ABS(CHECKSUM(NEWID()) % 2200) / 100.0)
                WHEN 'Home' THEN 5.00 + (ABS(CHECKSUM(NEWID()) % 4500) / 100.0)
                WHEN 'Sports' THEN 7.00 + (ABS(CHECKSUM(NEWID()) % 5500) / 100.0)
                WHEN 'Kids' THEN 4.00 + (ABS(CHECKSUM(NEWID()) % 2500) / 100.0)
                WHEN 'Clearance' THEN 2.00 + (ABS(CHECKSUM(NEWID()) % 1800) / 100.0)
                ELSE 4.00 + (ABS(CHECKSUM(NEWID()) % 5200) / 100.0)
            END
            AS DECIMAL(12,2)
        ) AS base_cost
) base
CROSS APPLY
(
    SELECT
        CAST(base.base_cost AS DECIMAL(12,2)) AS standard_cost,
        CAST
        (
            base.base_cost *
            CASE b.brand_segment
                WHEN 'Premium' THEN 2.40 + (ABS(CHECKSUM(NEWID()) % 60) / 100.0)
                WHEN 'Mid' THEN 1.90 + (ABS(CHECKSUM(NEWID()) % 45) / 100.0)
                ELSE 1.55 + (ABS(CHECKSUM(NEWID()) % 35) / 100.0)
            END
            AS DECIMAL(12,2)
        ) AS standard_price
) price
WHERE n.n <= @ProductCount
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.dim_producto p
      WHERE p.product_code = 'PROD' + RIGHT('000000' + CONVERT(VARCHAR(6), n.n), 6)
  );

/* ================================================================
   Pools para generar ventas
================================================================ */

IF OBJECT_ID('tempdb..#product_pool') IS NOT NULL DROP TABLE #product_pool;
IF OBJECT_ID('tempdb..#customer_pool') IS NOT NULL DROP TABLE #customer_pool;

SELECT
    ROW_NUMBER() OVER (ORDER BY product_id) AS rn,
    product_id,
    standard_cost,
    standard_price
INTO #product_pool
FROM dbo.dim_producto
WHERE is_active = 1;

CREATE UNIQUE CLUSTERED INDEX IX_product_pool_rn ON #product_pool(rn);

SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id) AS rn,
    customer_id
INTO #customer_pool
FROM dbo.dim_cliente
WHERE is_active = 1;

CREATE UNIQUE CLUSTERED INDEX IX_customer_pool_rn ON #customer_pool(rn);

DECLARE @ProductPoolCount INT = (SELECT COUNT(*) FROM #product_pool);
DECLARE @CustomerPoolCount INT = (SELECT COUNT(*) FROM #customer_pool);

IF @ProductPoolCount = 0 OR @CustomerPoolCount = 0
BEGIN
    THROW 50002, 'No hay productos o clientes activos para generar ventas.', 1;
END;

DECLARE @ChannelWeb INT = (SELECT channel_id FROM dbo.dim_canal WHERE channel_name = 'Web Propia');
DECLARE @ChannelAmazon INT = (SELECT channel_id FROM dbo.dim_canal WHERE channel_name = 'Amazon');
DECLARE @ChannelMiravia INT = (SELECT channel_id FROM dbo.dim_canal WHERE channel_name = 'Miravia');
DECLARE @ChannelShein INT = (SELECT channel_id FROM dbo.dim_canal WHERE channel_name = 'Shein');

DECLARE @PayCard INT = (SELECT payment_method_id FROM dbo.dim_metodo_pago WHERE payment_method_name = 'Tarjeta');
DECLARE @PayPaypal INT = (SELECT payment_method_id FROM dbo.dim_metodo_pago WHERE payment_method_name = 'PayPal');
DECLARE @PayTransfer INT = (SELECT payment_method_id FROM dbo.dim_metodo_pago WHERE payment_method_name = 'Transferencia');
DECLARE @PayCod INT = (SELECT payment_method_id FROM dbo.dim_metodo_pago WHERE payment_method_name = 'Contra reembolso');

DECLARE @ShipStandard INT =
(
    SELECT TOP (1) shipment_id
    FROM dbo.dim_envio
    WHERE shipment_type = 'Standard'
    ORDER BY shipment_id
);
DECLARE @ShipExpress INT =
(
    SELECT TOP (1) shipment_id
    FROM dbo.dim_envio
    WHERE shipment_type = 'Express'
    ORDER BY shipment_id
);
DECLARE @ShipPickup INT =
(
    SELECT TOP (1) shipment_id
    FROM dbo.dim_envio
    WHERE shipment_type = 'Pickup'
    ORDER BY shipment_id
);
DECLARE @ShipInternational INT =
(
    SELECT TOP (1) shipment_id
    FROM dbo.dim_envio
    WHERE shipment_type = 'International'
    ORDER BY shipment_id
);

/* ================================================================
   Ventas simuladas
================================================================ */

INSERT INTO dbo.fact_ventas
(
    order_id,
    date_id,
    product_id,
    customer_id,
    channel_id,
    promotion_id,
    payment_method_id,
    shipment_id,
    units_sold,
    gross_unit_price,
    discount_amount,
    product_cost_amount,
    commission_amount,
    payment_fee_amount,
    allocated_shipping_cost
)
SELECT
    'ORD' + CONVERT(CHAR(8), sale.sale_date, 112) + '-' + RIGHT('00000000' + CONVERT(VARCHAR(8), ((n.n - 1) / 2) + 1), 8),
    d.date_id,
    pp.product_id,
    cp.customer_id,
    ch.channel_id,
    CASE WHEN promo.use_promotion = 1 THEN ap.promotion_id ELSE NULL END,
    pm.payment_method_id,
    sh.shipment_id,
    qty.units_sold,
    money.gross_unit_price,
    money.discount_amount,
    money.product_cost_amount,
    money.commission_amount,
    money.payment_fee_amount,
    money.allocated_shipping_cost
FROM #numbers n
CROSS APPLY
(
    SELECT DATEADD(DAY, ABS(CHECKSUM(NEWID()) % (DATEDIFF(DAY, @StartDate, @EndDate) + 1)), @StartDate) AS sale_date
) sale
INNER JOIN dbo.dim_fecha d
    ON d.full_date = sale.sale_date
CROSS APPLY
(
    SELECT
        ABS(CHECKSUM(NEWID()) % 100) AS channel_roll,
        ABS(CHECKSUM(NEWID()) % 100) AS payment_roll,
        ABS(CHECKSUM(NEWID()) % 100) AS shipment_roll,
        ABS(CHECKSUM(NEWID()) % 100) AS quantity_roll,
        ABS(CHECKSUM(NEWID()) % 100) AS promo_roll,
        1 + ABS(CHECKSUM(NEWID()) % @ProductPoolCount) AS product_rn,
        1 + ABS(CHECKSUM(NEWID()) % @CustomerPoolCount) AS customer_rn
) r
INNER JOIN #product_pool pp
    ON pp.rn = r.product_rn
INNER JOIN #customer_pool cp
    ON cp.rn = r.customer_rn
CROSS APPLY
(
    SELECT
        CASE
            WHEN r.channel_roll < 30 THEN @ChannelWeb
            WHEN r.channel_roll < 68 THEN @ChannelAmazon
            WHEN r.channel_roll < 86 THEN @ChannelMiravia
            ELSE @ChannelShein
        END AS channel_id
) channel_choice
INNER JOIN dbo.dim_canal ch
    ON ch.channel_id = channel_choice.channel_id
CROSS APPLY
(
    SELECT
        CASE
            WHEN r.payment_roll < 62 THEN @PayCard
            WHEN r.payment_roll < 84 THEN @PayPaypal
            WHEN r.payment_roll < 94 THEN @PayTransfer
            ELSE @PayCod
        END AS payment_method_id
) payment_choice
INNER JOIN dbo.dim_metodo_pago pm
    ON pm.payment_method_id = payment_choice.payment_method_id
CROSS APPLY
(
    SELECT
        CASE
            WHEN r.shipment_roll < 66 THEN @ShipStandard
            WHEN r.shipment_roll < 82 THEN @ShipExpress
            WHEN r.shipment_roll < 96 THEN @ShipPickup
            ELSE @ShipInternational
        END AS shipment_id
) shipment_choice
INNER JOIN dbo.dim_envio sh
    ON sh.shipment_id = shipment_choice.shipment_id
OUTER APPLY
(
    SELECT TOP (1)
        promotion_id,
        discount_pct
    FROM dbo.dim_promocion pr
    WHERE sale.sale_date BETWEEN pr.start_date AND pr.end_date
      AND pr.is_active = 1
    ORDER BY CHECKSUM(NEWID(), n.n)
) ap
CROSS APPLY
(
    SELECT
        CASE
            WHEN ap.promotion_id IS NOT NULL AND r.promo_roll < 65 THEN 1
            ELSE 0
        END AS use_promotion
) promo
CROSS APPLY
(
    SELECT
        CASE
            WHEN r.quantity_roll < 68 THEN 1
            WHEN r.quantity_roll < 88 THEN 2
            WHEN r.quantity_roll < 97 THEN 3
            ELSE 4
        END AS units_sold
) qty
CROSS APPLY
(
    SELECT
        CAST(pp.standard_price * (0.94 + (ABS(CHECKSUM(NEWID()) % 13) / 100.0)) AS DECIMAL(12,2)) AS gross_unit_price,
        CAST
        (
            CASE
                WHEN promo.use_promotion = 1 THEN ap.discount_pct
                WHEN ABS(CHECKSUM(NEWID()) % 100) < 10 THEN 0.0500
                ELSE 0.0000
            END
            AS DECIMAL(8,4)
        ) AS discount_pct
) price
CROSS APPLY
(
    SELECT
        CAST(qty.units_sold * price.gross_unit_price AS DECIMAL(18,2)) AS gross_sales_amount,
        CAST(qty.units_sold * price.gross_unit_price * price.discount_pct AS DECIMAL(12,2)) AS discount_amount,
        CAST(qty.units_sold * pp.standard_cost AS DECIMAL(12,2)) AS product_cost_amount
) base_amounts
CROSS APPLY
(
    SELECT
        CAST(base_amounts.gross_sales_amount - base_amounts.discount_amount AS DECIMAL(18,2)) AS net_sales_amount
) net
CROSS APPLY
(
    SELECT
        price.gross_unit_price,
        base_amounts.discount_amount,
        base_amounts.product_cost_amount,
        CAST(net.net_sales_amount * ch.default_commission_pct AS DECIMAL(12,2)) AS commission_amount,
        CAST((net.net_sales_amount * pm.fee_pct) + pm.fee_fixed AS DECIMAL(12,2)) AS payment_fee_amount,
        CAST
        (
            sh.estimated_shipping_cost *
            CASE
                WHEN ch.channel_type = 'Marketplace' THEN 0.60
                WHEN qty.units_sold >= 3 THEN 0.75
                ELSE 1.00
            END
            AS DECIMAL(12,2)
        ) AS allocated_shipping_cost
) money
WHERE n.n <= @SalesLineCount;

/* ================================================================
   Inventario semanal por producto y almacen
================================================================ */

INSERT INTO dbo.fact_inventario
(
    date_id,
    product_id,
    warehouse_id,
    stock_available,
    stock_reserved,
    incoming_units,
    reorder_point,
    stockout_risk_flag
)
SELECT
    d.date_id,
    p.product_id,
    w.warehouse_id,
    stock.stock_available,
    stock.stock_reserved,
    stock.incoming_units,
    stock.reorder_point,
    CASE WHEN stock.stock_available <= stock.reorder_point THEN 1 ELSE 0 END
FROM dbo.dim_fecha d
CROSS JOIN dbo.dim_producto p
CROSS JOIN dbo.dim_almacen w
CROSS APPLY
(
    SELECT
        CASE
            WHEN p.standard_price >= 80 THEN 8 + ABS(CHECKSUM(NEWID()) % 40)
            WHEN p.standard_price >= 40 THEN 15 + ABS(CHECKSUM(NEWID()) % 80)
            ELSE 25 + ABS(CHECKSUM(NEWID()) % 140)
        END AS base_stock,
        5 + ABS(CHECKSUM(NEWID()) % 30) AS reorder_point,
        ABS(CHECKSUM(NEWID()) % 40) AS incoming_units
) seed
CROSS APPLY
(
    SELECT
        CASE
            WHEN w.capacity_level = 'Alta' THEN seed.base_stock + ABS(CHECKSUM(NEWID()) % 80)
            ELSE seed.base_stock / 2 + ABS(CHECKSUM(NEWID()) % 45)
        END AS stock_available,
        ABS(CHECKSUM(NEWID()) % 12) AS stock_reserved,
        seed.incoming_units,
        seed.reorder_point
) stock
WHERE d.full_date BETWEEN @StartDate AND @EndDate
  AND DATEDIFF(DAY, @StartDate, d.full_date) % 7 = 0
  AND p.is_active = 1
  AND w.is_active = 1;

SELECT 'dim_fecha' AS object_name, COUNT(*) AS rows_count FROM dbo.dim_fecha
UNION ALL SELECT 'dim_categoria', COUNT(*) FROM dbo.dim_categoria
UNION ALL SELECT 'dim_marca', COUNT(*) FROM dbo.dim_marca
UNION ALL SELECT 'dim_proveedor', COUNT(*) FROM dbo.dim_proveedor
UNION ALL SELECT 'dim_cliente', COUNT(*) FROM dbo.dim_cliente
UNION ALL SELECT 'dim_promocion', COUNT(*) FROM dbo.dim_promocion
UNION ALL SELECT 'dim_producto', COUNT(*) FROM dbo.dim_producto
UNION ALL SELECT 'fact_ventas', COUNT(*) FROM dbo.fact_ventas
UNION ALL SELECT 'fact_inventario', COUNT(*) FROM dbo.fact_inventario;

COMMIT TRANSACTION;

PRINT 'Seed realista creado correctamente para TFM_MarginAnalytics.';
GO

