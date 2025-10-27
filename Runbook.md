# A.Arsitektur Sederhana

## Alur Sistem
**Sumber data → Pipeline ETL/ELT (Airflow) → Data Warehouse (SQL Server) → Visualisasi / Analitik (Grafana / Superset / Metabase / Jupyter)**

---

## B.Langkah-Langkah

### 1. Clone dari Github dan Menambahkan env
```bash
git clone <repository-url>
cd DW_Project_Kelompok22
```

```cp .env.example .env```

### 2.	Mengatur .env berisi variabel (DB user, password, host, port, nama DB) agar hard-code kredensial.
#### 1) .env

```
ACCEPT_EULA=Y
 MSSQL_PID=Developer
 MSSQL_SA_PASSWORD=DWKelompok_4!
 MSSQL_USER=sa
 MSSQL_HOST=sqlserver
 MSSQL_PORT=1433
 MSSQL_DB=PTXYZ_DataWarehouse
```
#### 2) docker-compose.yml
##### Sebelum:
```
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: ptxyz_sqlserver
    hostname: sqlserver
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=${MSSQL_SA_PASSWORD:-PTXYZSecure123!}
      - MSSQL_SA_PASSWORD=${MSSQL_SA_PASSWORD:-PTXYZSecure123!}
      - MSSQL_PID=${MSSQL_PID:-Express}
      - MSSQL_USER=sa
    ports:
      - "1433:1433"
    ...
    healthcheck:
      test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'PTXYZSecure123!' -Q 'SELECT 1' -C -N"]
```

##### Sesudah:
```
sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: ptxyz_sqlserver
    hostname: ${MSSQL_HOST}
    environment:
      - ACCEPT_EULA=${ACCEPT_EULA}
      - MSSQL_SA_PASSWORD=${MSSQL_SA_PASSWORD}
      - MSSQL_PID=${MSSQL_PID}
    ports:
      - "${MSSQL_PORT}:1433"
    
    ...

    healthcheck:
      test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '${MSSQL_SA_PASSWORD}' -Q 'SELECT 1' -C -N"]
```



#### 3) standalone_etl.py
##### Sebelum:
```
    def get_sql_connection():
    """Create SQL Server connection"""
    try:
        conn = pymssql.connect(
            server='localhost',
            port=1433,
            database='PTXYZ_DataWarehouse',
            user='sa',
            password='PTXYZSecure123!',
            timeout=30
        )
        return conn
    except Exception as e:
        logging.error(f"Error connecting to SQL Server: {str(e)}")
```

##### Sesudah:
```
def get_sql_connection():
    try:
        server = os.getenv('MSSQL_HOST')
        port = int(os.getenv('MSSQL_PORT'))
        database = os.getenv('MSSQL_DB')
        user = os.getenv('MSSQL_USER')
        password = os.getenv('MSSQL_SA_PASSWORD')  # 

        conn = pymssql.connect(
            server=server, port=port, database=database,
            user=user, password=password, timeout=30, charset='UTF-8'
        )
        return conn
    except Exception as e:
        logging.error(f"Error connecting to SQL Server: {str(e)}")
        raise
```

#### 4)	ptxyz_fact_loader.py dan ptxyz_dimension_loader.py
##### Sebelum:
```
   def get_sql_connection():
    """Get SQL Server connection"""
    sql_password = os.getenv('MSSQL_SA_PASSWORD', 'PTXYZSecure123!')
    
    return pymssql.connect(
        server='ptxyz_sqlserver',
        port=1433,
        database='PTXYZ_DataWarehouse',
        user='sa',
        password=sql_password,
        timeout=30
    )
```

##### Sesudah:
```
def get_sql_connection():
    sql_host = os.getenv('MSSQL_HOST')
    sql_port = int(os.getenv('MSSQL_PORT'))
    sql_user = os.getenv('MSSQL_USER')
    sql_password = os.getenv('MSSQL_SA_PASSWORD')
    sql_db = os.getenv('MSSQL_DB')
    
    return pymssql.connect(
        server=sql_host,
        port=sql_port,
        database=sql_db,
        user=sql_user,
        password=sql_password,
        timeout=30
    )
```

### 3.	Menjalankan perintah sesuai readme
#### 1)	docker-compose up -d (memulai semua service)
#### 2)	docker compose ps (check status)
#### 3)	python standalone_etl.py (menjalankan ETL)
#### 4)	membuat test_connection.py (untuk mengetest koneksi sql dari airflow ptxyz_fact_loader.py dan ptxyz_dimension_loader.py)
```
from dotenv import load_dotenv
import os
import pymssql

load_dotenv()  # load environment variable dari .env

sql_host = os.getenv('MSSQL_HOST')
sql_port = int(os.getenv('MSSQL_PORT'))
sql_user = os.getenv('MSSQL_USER')
sql_password = os.getenv('MSSQL_SA_PASSWORD')
sql_db = os.getenv('MSSQL_DB')

try:
    conn = pymssql.connect(
        server=sql_host,
        port=sql_port,
        user=sql_user,
        password=sql_password,
        database=sql_db,
        timeout=5
    )
    cursor = conn.cursor()
    cursor.execute("SELECT GETDATE()")
    row = cursor.fetchone()
    print(f"✅ Connection successful! Server time: {row[0]}")
    conn.close()
except Exception as e:
    print(f"❌ Connection failed: {e}")
```
#### 5)	membuat validate.sql 
```
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
```
untuk membuktikan kepatuhan pada README:
- Skema: nama tabel/kolom/tipe sesuai README.
- Integritas: semua baris fakta punya FK yang valid; 0 orphan.
- Agregat: jika README menampilkan contoh hasil (angka total/rekap), hasil Anda harus sama.


## C.Bukti/Hasil
### 1. Hasil Validate
#### 1) Skema: nama tabel/kolom/tipe sesuai README
#### 2)	Integritas: semua baris fakta punya FK yang valid; 0 orphan.
#### 3)	Agregat: jika README menampilkan contoh hasil (angka total/rekap), hasil Anda harus sama.

### 2. Hasil test_connection.py


## D.Kendala dan Solusi
### 1. Folder plugins tidak ditemukan
Kendala:

Solusi:
Membuat folder plugin didalam folder airflow


### 2.	Error unicodeencoding
Kendala:
Windows default-nya pakai encoding cp1252 (bukan UTF-8).
Encoding ini tidak mendukung emoji atau beberapa simbol Unicode, seperti 🚀, ✅, 🔄, 📊, 🎉, dll.
 

Solusi:
Masukan $env:PYTHONUTF8 = "1 pada terminal


### 3.	Login Failed
Kendala:
Database tidak dibuat otomatis saat docker compose up -d
 
 

Solusi:
Mengubah file init-db.sh dari CRLF menjadi LF agar database dabat dibuat bersamaan dengan docker compose up -d

