import pymysql
import datetime

def execute_script_from_file_mysql(connection, filename):
    """Reads and executes an SQL script from a given file on a MySQL connection."""
    print(f"Executing {filename}...")
    with open(filename, 'r') as file:
        sql_script = file.read()
    cursor = connection.cursor()
    # Split the script on semicolons; note this simple split works for many cases.
    for statement in sql_script.split(';'):
        statement = statement.strip()
        if statement:
            cursor.execute(statement)
    connection.commit()
    cursor.close()
    print(f"Executed {filename} successfully.")

# MySQL connection parameters – adjust these to your environment.
db_config = {
    'host': 'localhost',
    'user': 'your_username',
    'password': 'your_password',
    'port': 3306,
    'charset': 'utf8mb4'
}

# ====================================================
# SECTION 1: Main Database (crnjakt_zagimore)
# ====================================================
print("=== Creating MAIN DATABASE: crnjakt_zagimore ===")
# Connect without a database first
conn = pymysql.connect(**db_config)
cursor = conn.cursor()
cursor.execute("CREATE DATABASE IF NOT EXISTS crnjakt_zagimore;")
conn.commit()
cursor.close()
conn.close()

# Connect to the main database
conn_main = pymysql.connect(db='crnjakt_zagimore', **db_config)
execute_script_from_file_mysql(conn_main, 'database_creation.ddl')
execute_script_from_file_mysql(conn_main, 'data_population.ddl')
conn_main.close()
print("Main database created and closed.")

# ====================================================
# SECTION 2: Warehouse Database (crnjakt_warehouse_zagimore)
# ====================================================
print("\n=== Creating WAREHOUSE DATABASE: crnjakt_warehouse_zagimore ===")
conn = pymysql.connect(**db_config)
cursor = conn.cursor()
cursor.execute("CREATE DATABASE IF NOT EXISTS crnjakt_warehouse_zagimore;")
conn.commit()
cursor.close()
conn.close()

conn_wh = pymysql.connect(db='crnjakt_warehouse_zagimore', **db_config)
execute_script_from_file_mysql(conn_wh, 'data_warehousing_db_creation.ddl')
conn_wh.close()
print("Warehouse database created and closed.")

# ====================================================
# SECTION 3: Data Staging Database (crnjakt_datastaging_zagimore)
# ====================================================
print("\n=== Creating DATA STAGING DATABASE: crnjakt_datastaging_zagimore ===")
conn = pymysql.connect(**db_config)
cursor = conn.cursor()
cursor.execute("CREATE DATABASE IF NOT EXISTS crnjakt_datastaging_zagimore;")
conn.commit()
cursor.close()
conn.close()

conn_staging = pymysql.connect(db='crnjakt_datastaging_zagimore', **db_config)
# Run the staging creation script
execute_script_from_file_mysql(conn_staging, 'data_staging_db_creation.ddl')

# For calendar_population.ddl, since MySQL supports stored procedures, try executing it.
# If it fails, you could simulate the calendar population using Python as in the sqlite3 version.
try:
    execute_script_from_file_mysql(conn_staging, 'calendar_population.ddl')
except Exception as e:
    print("Error executing calendar_population.ddl, simulating with Python. Error:", e)
    cursor = conn_staging.cursor()
    start_date = datetime.date(2013, 1, 1)
    n_days = 10000
    for i in range(n_days):
        full_date = start_date + datetime.timedelta(days=i)
        cursor.execute("INSERT INTO Calendar_Dimension (FullDate) VALUES (%s)", (full_date,))
    conn_staging.commit()
    cursor.close()

# Run remaining staging scripts
execute_script_from_file_mysql(conn_staging, 'populating_staging_dimension.ddl')
execute_script_from_file_mysql(conn_staging, 'populating_warehouse.ddl')
conn_staging.close()
print("Data staging database created and closed.")
