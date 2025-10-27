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
