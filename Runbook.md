# Arsitektur Sederhana

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
#### 4)	5)	membuat test_connection.py (untuk mengetest koneksi sql dari airflow ptxyz_fact_loader.py dan ptxyz_dimension_loader.py)
#### 5)	6)	membuat validate.sql 
untuk membuktikan kepatuhan pada README:
- Skema: nama tabel/kolom/tipe sesuai README.
- Integritas: semua baris fakta punya FK yang valid; 0 orphan.
- Agregat: jika README menampilkan contoh hasil (angka total/rekap), hasil Anda harus sama.


