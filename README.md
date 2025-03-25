Data Warehouse ETL Project
This repository contains the SQL and Python code used to create, populate, and update a data warehouse using PostgreSQL (with Supabase). The project demonstrates a complete ETL (Extract, Transform, Load) process from an operational schema and staging environment into a fully structured data warehouse.

Overview
The repository includes several SQL DDL scripts that:

Create schemas for operational data (e.g., zagimore), data staging, and the data warehouse.

Populate staging tables with raw data.

Transform and load data from staging into dimension tables and fact tables in the data warehouse.

Populate specific dimensions (such as the Calendar dimension) and fact tables (e.g., Revenue and Unit Sold).

A Python script is also provided to automate the execution of these SQL scripts, making it easier to update your data warehouse when new data is available.

Directory Structure
zagimore.ddl
Contains DDL commands to create the operational schema and tables for the primary data source.

datastaging.ddl
Contains DDL commands to set up the staging environment, where raw data is loaded and pre-processed.

ds_populating.ddl
Contains SQL queries that populate the data staging tables.

calendar_populate.ddl
Contains SQL code specifically for populating the Calendar dimension.

datawarehouse.ddl
Contains DDL commands to create the data warehouse schema and its tables.

dw_populating.ddl
Contains SQL queries to load dimension and fact tables in the data warehouse from the staging environment.

zagi_populating.ddl
Contains additional SQL scripts for populating the operational schema (if applicable).

python_script.py (or similar)
A Python script that automates the running of these SQL queries using the psycopg2 library.

ETL Process
The ETL process in this project consists of the following steps:

Extract & Transform (Data Staging):

Raw data is loaded into the operational schema.

Data is then transformed and loaded into the staging environment (using scripts in ds_populating.ddl and zagi_populating.ddl).

A temporary table (e.g., IntermediateFact) is created in the staging area to consolidate fact data.

Load (Data Warehouse):

Dimension tables are populated in the data warehouse by selecting and transforming data from staging (see dw_populating.ddl).

Fact tables are then loaded with detailed metrics like revenue and units sold.

Automation:

The provided Python script automates the execution of these queries, making it simple to refresh or update the data warehouse when new data becomes available.

How to Use
Database Setup:

Run the DDL scripts in the following order:

zagimore.ddl – Sets up the operational schema.

datastaging.ddl – Creates the staging schema and tables.

datawarehouse.ddl – Creates the data warehouse schema and tables.

Populate Staging Data:

Execute the scripts in ds_populating.ddl, zagi_populating.ddl, and calendar_populate.ddl to load and transform your raw data into the staging environment.After calendar_populate, the created function needs to be called

Load Data Warehouse:

Run the queries in dw_populating.ddl to load dimension and fact tables in the data warehouse from the staging tables.

Incremental Updates:

When new data is available, decide if you need a full refresh (e.g., using TRUNCATE before re-inserting) or an incremental update (using upsert logic) and adjust the scripts accordingly.


Make sure that join conditions in the ETL queries are correct to avoid duplicate rows.

The repository is designed for educational purposes and can be modified to suit more complex ETL requirements.

Conclusion
This project demonstrates how to design, populate, and update a data warehouse using MySQL, PostgreSQL, and python. The modular design allows for flexibility in managing and refreshing your data. Contributions and improvements are welcome!