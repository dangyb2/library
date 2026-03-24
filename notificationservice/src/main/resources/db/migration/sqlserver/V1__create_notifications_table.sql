IF OBJECT_ID(N'dbo.notifications', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.notifications (
        id VARCHAR(50) NOT NULL PRIMARY KEY,
        recipient_email NVARCHAR(255) NOT NULL,
        type VARCHAR(40) NOT NULL,
        subject NVARCHAR(200) NOT NULL,
        content NVARCHAR(MAX) NOT NULL,
        status VARCHAR(20) NOT NULL,
        retry_count INT NOT NULL,
        created_at DATETIME2 NOT NULL,
        sent_at DATETIME2 NULL
    );

    CREATE INDEX ix_notifications_status_retry_created
        ON dbo.notifications (status, retry_count, created_at);
END;
