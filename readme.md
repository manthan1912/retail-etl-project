# Azure Databricks Retail ETL Pipeline with ADF Orchestration

## Overview
This project demonstrates an end-to-end Azure data engineering workflow built using **Azure Databricks**, **PySpark**, **Azure Data Factory (ADF)**, and **Azure SQL Database**.

The solution processes raw retail transaction data in Databricks, creates cleaned **Silver** data and multiple **Gold** business aggregates, validates the outputs through a separate Databricks validation job, and uses ADF to orchestrate the full workflow with success/failure logging into Azure SQL Database.

---

## Architecture
**Raw retail data → Databricks ETL notebook → Silver and Gold Delta tables → Databricks validation notebook → ADF orchestration → Azure SQL run logging**

---

## Project Components

### Azure Databricks
This project uses two notebooks:

- `project3_retail_etl.ipynb`
- `project3_validation.ipynb`

The ETL notebook:
- loads raw retail data
- profiles data quality issues
- creates a cleaned Silver dataset
- creates Gold business aggregates
- writes Delta tables to Unity Catalog
- creates a DQ summary table

The validation notebook:
- checks that required Silver and Gold tables exist
- verifies that the output tables contain data
- raises an error if validation fails

### Azure Data Factory
ADF pipeline:
- `PL_Run_Project3_Databricks_Job`

ADF activities:
- `RUN_Project3_Databricks_Job`
- `RUN_Project3_Validation_Job`
- `LOG_Project3_Success`
- `LOG_Project3_Failure`

ADF first runs the main Databricks ETL job, then runs the validation job, and finally logs success or failure into Azure SQL Database. The ARM export shows these exact activities and dependencies.

### Azure SQL Database
Azure SQL is used for orchestration logging.

Objects used:
- `dbo.adf_pipeline_run_log`
- `dbo.sp_log_adf_pipeline_run`

The logging procedure writes:
- pipeline name
- pipeline run ID
- run status
- log message
- timestamp

### Unity Catalog / Delta Tables
The Databricks notebook persists transformed outputs as Delta tables, including:
- Silver transactional dataset
- Gold sales by country
- Gold top products
- Gold customer sales summary
- DQ run summary

---

## Data Processing Flow

### 1. Raw Data Load
The notebook reads raw online retail transaction data into a PySpark DataFrame.

### 2. Raw Data Profiling
The raw dataset is profiled for common data quality issues such as:
- missing descriptions
- missing customer IDs
- duplicate rows
- negative quantities
- non-positive prices

### 3. Silver Layer
A cleaned Silver dataset is created by:
- removing duplicate rows
- trimming text columns
- parsing invoice timestamp
- filtering invalid transactions
- creating a derived `line_amount` column

### 4. Gold Layer
Three Gold datasets are created:
- **sales by country**
- **top products by revenue**
- **customer sales summary**

### 5. DQ Summary
A DQ summary table is generated with run-level metrics such as:
- raw row count
- silver row count
- rejected/invalid counts
- missing value counts
- invalid quantity/price counts

### 6. Validation
A separate Databricks validation notebook confirms that the Silver and Gold output tables exist and contain rows.

### 7. ADF Orchestration

ADF runs the main Databricks ETL job, then the validation job, and logs either success or failure into Azure SQL Database. This orchestration is reflected in the exported pipeline template.

---

## Technology Stack
- Azure Databricks
- PySpark
- Azure Data Factory
- Azure SQL Database
- Unity Catalog
- Delta Lake

---

## ADF Configuration
From the exported ARM template:

- **Factory name:** `project3-adf-databricks`
- **Databricks linked service:** `AzureDatabricks1`
- **Azure SQL linked service:** `LS_Azure_SQL_Project3`
- **Databricks runtime:** `16.4.x-scala2.12`
- **Node type:** `Standard_DS3_v2`
- **Workers:** `1` 

---

## SQL Logging Objects

```sql
CREATE TABLE dbo.adf_pipeline_run_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    pipeline_name VARCHAR(200),
    pipeline_run_id VARCHAR(200),
    run_status VARCHAR(50),
    log_message VARCHAR(500),
    logged_at DATETIME DEFAULT GETDATE()
);

CREATE OR ALTER PROCEDURE dbo.sp_log_adf_pipeline_run
    @pipeline_name VARCHAR(200),
    @pipeline_run_id VARCHAR(200),
    @run_status VARCHAR(50),
    @log_message VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.adf_pipeline_run_log (
        pipeline_name,
        pipeline_run_id,
        run_status,
        log_message
    )
    VALUES (
        @pipeline_name,
        @pipeline_run_id,
        @run_status,
        @log_message
    );
END;
```
## Project Structure
```
├── README.md
├── adf/
│   ├── ARMTemplateForFactory.json
│   ├── ARMTemplateParametersForFactory.json
│   ├── ArmTemplate_master.json
│   ├── ArmTemplate_0.json
│   └── ArmTemplateParameters_master.json
├── databricks/
│   ├── project3_retail_etl.ipynb
│   └── project3_validation.ipynb
├── sql/
│   └── orchestration_logging.sql
└── screenshots/
```

## How to Run
1. Create the Azure Databricks workspace and notebook jobs.
2. Create the Azure SQL Database and run the logging SQL script.
3. Create the ADF linked services for:
     * Azure Databricks
     * Azure SQL Database
4. Import or deploy the ADF pipeline from the ARM template.
5. Run the ADF pipeline:
     * `PL_Run_Project3_Databricks_Job`
6. Verify:
     * Databricks ETL job succeeds
     * Databricks validation job succeeds
     * success/failure row is inserted into `dbo.adf_pipeline_run_log`

## Skills Demonstrated
- Azure Databricks notebook development
- PySpark transformations and aggregations
- Silver and Gold layer design
- Delta table persistence
- Data quality profiling and validation
- Azure Data Factory orchestration
- Azure SQL stored procedure logging
- Production-style success/failure workflow design

## Outcome

This project demonstrates a production-style Azure data engineering pattern where Databricks performs ETL and validation, while ADF orchestrates execution and Azure SQL captures operational run logs. It showcases PySpark-based transformation, multi-layer data modeling, validation-driven pipeline control, and cloud orchestration.
