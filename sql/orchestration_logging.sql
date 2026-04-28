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