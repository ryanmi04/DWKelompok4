USE PTXYZ_DataWarehouse;
GO

PRINT '=== 🔍 Tes Kepatuhan Schema ===';

SELECT 'dim.DimTime' AS expected,
       CASE WHEN OBJECT_ID('dim.DimTime', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END AS status
UNION ALL
SELECT 'dim.DimSite',
       CASE WHEN OBJECT_ID('dim.DimSite', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'dim.DimEquipment',
       CASE WHEN OBJECT_ID('dim.DimEquipment', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'dim.DimMaterial',
       CASE WHEN OBJECT_ID('dim.DimMaterial', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'dim.DimEmployee',
       CASE WHEN OBJECT_ID('dim.DimEmployee', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'dim.DimShift',
       CASE WHEN OBJECT_ID('dim.DimShift', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'dim.DimProject',
       CASE WHEN OBJECT_ID('dim.DimProject', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'dim.DimAccount',
       CASE WHEN OBJECT_ID('dim.DimAccount', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'fact.FactEquipmentUsage',
       CASE WHEN OBJECT_ID('fact.FactEquipmentUsage', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'fact.FactProduction',
       CASE WHEN OBJECT_ID('fact.FactProduction', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END
UNION ALL
SELECT 'fact.FactFinancialTransaction',
       CASE WHEN OBJECT_ID('fact.FactFinancialTransaction', 'U') IS NOT NULL THEN 'OK' ELSE 'MISSING' END;
GO


PRINT '=== 🔗 Cek Integritas FK ===';

-- Ringkasan orphan per-FK (harus 0)
WITH OrphanPerFK AS (
    -- FactEquipmentUsage
    SELECT 'fact.FactEquipmentUsage.time_key -> dim.DimTime' AS fk, COUNT(*) AS orphan
    FROM fact.FactEquipmentUsage f
    LEFT JOIN dim.DimTime d ON f.time_key = d.time_key
    WHERE d.time_key IS NULL
    UNION ALL
    SELECT 'fact.FactEquipmentUsage.site_key -> dim.DimSite', COUNT(*)
    FROM fact.FactEquipmentUsage f
    LEFT JOIN dim.DimSite d ON f.site_key = d.site_key
    WHERE d.site_key IS NULL
    UNION ALL
    SELECT 'fact.FactEquipmentUsage.equipment_key -> dim.DimEquipment', COUNT(*)
    FROM fact.FactEquipmentUsage f
    LEFT JOIN dim.DimEquipment d ON f.equipment_key = d.equipment_key
    WHERE d.equipment_key IS NULL

    -- FactProduction
    UNION ALL
    SELECT 'fact.FactProduction.time_key -> dim.DimTime', COUNT(*)
    FROM fact.FactProduction f
    LEFT JOIN dim.DimTime d ON f.time_key = d.time_key
    WHERE d.time_key IS NULL
    UNION ALL
    SELECT 'fact.FactProduction.site_key -> dim.DimSite', COUNT(*)
    FROM fact.FactProduction f
    LEFT JOIN dim.DimSite d ON f.site_key = d.site_key
    WHERE d.site_key IS NULL
    UNION ALL
    SELECT 'fact.FactProduction.material_key -> dim.DimMaterial', COUNT(*)
    FROM fact.FactProduction f
    LEFT JOIN dim.DimMaterial d ON f.material_key = d.material_key
    WHERE d.material_key IS NULL
    UNION ALL
    SELECT 'fact.FactProduction.employee_key -> dim.DimEmployee', COUNT(*)
    FROM fact.FactProduction f
    LEFT JOIN dim.DimEmployee d ON f.employee_key = d.employee_key
    WHERE d.employee_key IS NULL
    UNION ALL
    SELECT 'fact.FactProduction.shift_key -> dim.DimShift', COUNT(*)
    FROM fact.FactProduction f
    LEFT JOIN dim.DimShift d ON f.shift_key = d.shift_key
    WHERE d.shift_key IS NULL

    -- FactFinancialTransaction
    UNION ALL
    SELECT 'fact.FactFinancialTransaction.time_key -> dim.DimTime', COUNT(*)
    FROM fact.FactFinancialTransaction f
    LEFT JOIN dim.DimTime d ON f.time_key = d.time_key
    WHERE d.time_key IS NULL
    UNION ALL
    SELECT 'fact.FactFinancialTransaction.site_key -> dim.DimSite', COUNT(*)
    FROM fact.FactFinancialTransaction f
    LEFT JOIN dim.DimSite d ON f.site_key = d.site_key
    WHERE d.site_key IS NULL
    UNION ALL
    SELECT 'fact.FactFinancialTransaction.project_key -> dim.DimProject', COUNT(*)
    FROM fact.FactFinancialTransaction f
    LEFT JOIN dim.DimProject d ON f.project_key = d.project_key
    WHERE d.project_key IS NULL
    UNION ALL
    SELECT 'fact.FactFinancialTransaction.account_key -> dim.DimAccount', COUNT(*)
    FROM fact.FactFinancialTransaction f
    LEFT JOIN dim.DimAccount d ON f.account_key = d.account_key
    WHERE d.account_key IS NULL
)
SELECT 
    fk,
    orphan,
    CASE WHEN orphan = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM OrphanPerFK
ORDER BY CASE WHEN orphan > 0 THEN 0 ELSE 1 END, fk;
GO

PRINT '=== 🧩 Validasi Jumlah Record Sesuai README ===';

SELECT 
    'dim.DimTime' AS table_name, COUNT(*) AS actual, 830 AS expected,
    CASE WHEN COUNT(*) = 830 THEN 'PASS' ELSE 'FAIL' END AS status
FROM dim.DimTime
UNION ALL
SELECT 'dim.DimSite', COUNT(*), 1747, CASE WHEN COUNT(*) = 1747 THEN 'PASS' ELSE 'FAIL' END FROM dim.DimSite
UNION ALL
SELECT 'dim.DimEquipment', COUNT(*), 6, CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END FROM dim.DimEquipment
UNION ALL
SELECT 'dim.DimMaterial', COUNT(*), 5, CASE WHEN COUNT(*) = 5 THEN 'PASS' ELSE 'FAIL' END FROM dim.DimMaterial
UNION ALL
SELECT 'dim.DimEmployee', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN 'PASS' ELSE 'FAIL' END FROM dim.DimEmployee
UNION ALL
SELECT 'dim.DimShift', COUNT(*), 3, CASE WHEN COUNT(*) = 3 THEN 'PASS' ELSE 'FAIL' END FROM dim.DimShift
UNION ALL
SELECT 'dim.DimProject', COUNT(*), 50, CASE WHEN COUNT(*) = 50 THEN 'PASS' ELSE 'FAIL' END FROM dim.DimProject
UNION ALL
SELECT 'dim.DimAccount', COUNT(*), 30, CASE WHEN COUNT(*) = 30 THEN 'PASS' ELSE 'FAIL' END FROM dim.DimAccount
UNION ALL
SELECT 'fact.FactEquipmentUsage', COUNT(*), 236892, CASE WHEN COUNT(*) = 236892 THEN 'PASS' ELSE 'FAIL' END FROM fact.FactEquipmentUsage
UNION ALL
SELECT 'fact.FactProduction', COUNT(*), 2261, CASE WHEN COUNT(*) = 2261 THEN 'PASS' ELSE 'FAIL' END FROM fact.FactProduction
UNION ALL
SELECT 'fact.FactFinancialTransaction', COUNT(*), 115901, CASE WHEN COUNT(*) = 115901 THEN 'PASS' ELSE 'FAIL' END FROM fact.FactFinancialTransaction;
GO



PRINT '=== ✅ Tes Validasi Selesai ===';
GO
