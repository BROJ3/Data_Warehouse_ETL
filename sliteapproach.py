import sqlite3
import datetime

def execute_script_from_file(cursor, filename):
    """Reads and executes an SQL script from a given file."""
    print(f"Executing {filename}...")
    with open(filename, 'r') as file:
        sql_script = file.read()
    cursor.executescript(sql_script)
    print(f"Executed {filename} successfully.")

# ====================================================
# SECTION 1: Main Database (crnjakt_zagimore)
# ====================================================
print("=== Creating MAIN DATABASE: crnjakt_zagimore ===")
main_db = sqlite3.connect('crnjakt_zagimore.db')
main_cursor = main_db.cursor()

execute_script_from_file(main_cursor, 'database_creation.ddl')
main_db.commit()

execute_script_from_file(main_cursor, 'data_population.ddl')
main_db.commit()

main_cursor.close()
main_db.close()
print("Main database created and closed.")

# ====================================================
# SECTION 2: Warehouse Database (crnjakt_warehouse_zagimore)
# ====================================================
print("\n=== Creating WAREHOUSE DATABASE: crnjakt_warehouse_zagimore ===")
warehouse_db = sqlite3.connect('crnjakt_warehouse_zagimore.db')
warehouse_cursor = warehouse_db.cursor()

execute_script_from_file(warehouse_cursor, 'data_warehousing_db_creation.ddl')
warehouse_db.commit()

warehouse_cursor.close()
warehouse_db.close()
print("Warehouse database created and closed.")


# ====================================================
# SECTION 3: Data Staging Database (crnjakt_datastaging_zagimore)
# ====================================================
print("\n=== Creating DATA STAGING DATABASE: crnjakt_datastaging_zagimore ===")
staging_db = sqlite3.connect('crnjakt_datastaging_zagimore.db')
staging_cursor = staging_db.cursor()

# 1. Run the staging creation DDL
execute_script_from_file(staging_cursor, 'data_staging_db_creation.ddl')
staging_db.commit()

# 2. Calendar population step: simulate calendar_population.ddl using Python.
print("Populating Calendar_Dimension table using Python...")
start_date = datetime.date(2013, 1, 1)
n_days = 10000  # Number of days to insert
for i in range(n_days):
    full_date = start_date + datetime.timedelta(days=i)
    staging_cursor.execute("INSERT INTO Calendar_Dimension (FullDate) VALUES (?)", (full_date,))
staging_db.commit()

# 3. BEFORE running the staging dimension script, attach the main database.
# This makes crnjakt_zagimore.customer available to the SQL code as expected.
staging_cursor.execute("ATTACH DATABASE 'crnjakt_zagimore.db' AS crnjakt_zagimore;")

# 4. Now run the remaining staging scripts
execute_script_from_file(staging_cursor, 'populating_staging_dimension.ddl')
staging_db.commit()

execute_script_from_file(staging_cursor, 'populating_warehouse.ddl')
staging_db.commit()

staging_cursor.close()
staging_db.close()
print("Data staging database created and closed.")
