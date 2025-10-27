# Arsitektur Sederhana

## Alur Sistem
**Sumber data → Pipeline ETL/ELT (Airflow) → Data Warehouse (SQL Server) → Visualisasi / Analitik (Grafana / Superset / Metabase / Jupyter)**

---

## Langkah-Langkah

### 1. Clone dari Github dan Menambahkan env
```bash
git clone <repository-url>
cd DW_Project_Kelompok22
```

```cp .env.example .env```

### 2.	Mengatur .env berisi variabel (DB user, password, host, port, nama DB) agar hard-code kredensial.
        1) .env
           ```ACCEPT_EULA=Y
           MSSQL_PID=Developer
           MSSQL_SA_PASSWORD=DWKelompok_4!
           MSSQL_USER=sa
           MSSQL_HOST=sqlserver
           MSSQL_PORT=1433
           MSSQL_DB=PTXYZ_DataWarehouse ```

### 3. Menjalankan Layanan dengan Docker
#### Menjalankan semua layanan:
```bash
docker-compose up -d
```

#### Verifikasi status layanan:
```bash
docker-compose ps
```

---

## 4. Setting File `.env`
Agar tidak hardcode, gunakan file `.env` sebagai berikut:

```bash
# ================================
# DATABASE CONFIGURATION
# ================================

# SQL Server
ACCEPT_EULA=Y
MSSQL_PID=Developer
MSSQL_SA_PASSWORD=DWKelompok_4!
MSSQL_USER=sa
MSSQL_HOST=127.0.0.1
MSSQL_PORT=1433
MSSQL_DB=PTXYZ_DataWarehouse
```

---

## 5. Konfigurasi `docker-compose.yml`
```yaml
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
  volumes:
    - sqlserver_data:/var/opt/mssql
    - ./data:/data
    - ./init-scripts:/init-scripts
    - ./misi3:/scripts
  networks:
    - dw_network
  restart: unless-stopped
  healthcheck:
    test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '${MSSQL_SA_PASSWORD}' -Q 'SELECT 1' -C -N"]
    interval: 30s
    timeout: 10s
    retries: 10
    start_period: 60s
```

---

## 6. Script Koneksi SQL

### `ptxyz_fact_loader.py`
```python
def get_sql_connection():
    """Get SQL Server connection using environment variables (.env)"""
    server = os.getenv('MSSQL_HOST')
    port = int(os.getenv('MSSQL_PORT'))
    database = os.getenv('MSSQL_DB')
    user = os.getenv('MSSQL_USER')
    password = os.getenv('MSSQL_SA_PASSWORD')

    logging.info(f"Connecting to SQL Server: {server}:{port}, DB: {database}, User: {user}")

    return pymssql.connect(
        server=server,
        port=port,
        user=user,
        password=password,
        database=database,
        timeout=30
    )
```

### `ptxyz_dimension_loader.py`
```python
def get_sql_connection():
    """Get SQL Server connection using environment variables (.env)"""
    server = os.getenv('MSSQL_HOST', 'sqlserver')
    port = int(os.getenv('MSSQL_PORT', '1433'))
    database = os.getenv('MSSQL_DB', 'PTXYZ_DataWarehouse')
    user = os.getenv('MSSQL_USER', 'sa')
    password = os.getenv('MSSQL_SA_PASSWORD', 'PTXYZSecure123!')

    logging.info(f"Connecting to SQL Server: {server}:{port}, DB: {database}, User: {user}")

    return pymssql.connect(
        server=server,
        port=port,
        user=user,
        password=password,
        database=database,
        timeout=30
    )
```

### `standalone_etl.py`
```python
def get_sql_connection():
    try:
        server = os.getenv('MSSQL_HOST')
        port = int(os.getenv('MSSQL_PORT'))
        database = os.getenv('MSSQL_DB')
        user = os.getenv('MSSQL_USER')
        password = os.getenv('MSSQL_SA_PASSWORD')  # <-- ambil dari .env

        conn = pymssql.connect(
            server=server, port=port, database=database,
            user=user, password=password, timeout=30, charset='UTF-8'
        )
        return conn
    except Exception as e:
        logging.error(f"Error connecting to SQL Server: {str(e)}")
        raise
```

---

## 7. Membuat Schema di Docker
```bash
docker cp .\init-scripts\create-schema.sql ptxyz_sqlserver:/tmp/create-schema.sql
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "DWKelompok_4#" -d master -C -N -i /tmp/create-schema.sql
```

Lalu lakukan proses **ETL**.

---

## 8. File Validasi SQL

### Tes Kepatuhan Schema
```sql
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
```

---

### Validasi Jumlah Record
```sql
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
```

---

### Cek Integritas Foreign Key
```sql
PRINT '=== 🔗 Cek Integritas Foreign Key ===';

-- Cek FactProduction -> DimSite
SELECT COUNT(*) AS orphan_site
FROM fact.FactProduction f
LEFT JOIN dim.DimSite d ON f.site_key = d.site_key
WHERE d.site_key IS NULL;

-- Cek FactProduction -> DimTime
SELECT COUNT(*) AS orphan_time
FROM fact.FactProduction f
LEFT JOIN dim.DimTime t ON f.time_key = t.time_key
WHERE t.time_key IS NULL;

-- Cek FactFinancialTransaction -> DimProject
SELECT COUNT(*) AS orphan_project
FROM fact.FactFinancialTransaction f
LEFT JOIN dim.DimProject p ON f.project_key = p.project_key
WHERE p.project_key IS NULL;
GO
```

---

### Validasi Agregat Contoh
```sql
PRINT '=== 📊 Validasi Agregat Contoh ===';

SELECT 
    SUM(operating_hours) AS total_operating_hours,
    SUM(downtime_hours) AS total_downtime,
    SUM(maintenance_cost) AS total_maintenance_cost
FROM fact.FactEquipmentUsage;
GO

PRINT '=== ✅ Tes Validasi Selesai ===';
GO
```

---

## 9. Bukti Hasil
Bukti hasil validasi dapat ditampilkan setelah eksekusi skrip di atas untuk memastikan semua tabel dan relasi valid.

---

## 10. Kendala dan Solusi

### 🔸 Masalah Koneksi Database
- **Masalah:** Terjadi error karena port tidak terbuka atau konfigurasi `.env` salah.  
- **Solusi:** Pastikan SQL Server berjalan dan lakukan konfigurasi ulang koneksi.

### 🔸 Masalah Encoding
- **Masalah:** Gagal menulis log dengan karakter Unicode (emoji).  
- **Solusi:** Ubah konfigurasi logging untuk mendukung **UTF-8**.
