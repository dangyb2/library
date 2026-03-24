IF OBJECT_ID(N'dbo.readers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.readers (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        name NVARCHAR(255) NOT NULL,
        email NVARCHAR(255) NULL,
        phone NVARCHAR(255) NULL,
        membership_expire_at DATE NOT NULL,
        status NVARCHAR(32) NULL,
        suspend_reason NVARCHAR(255) NULL
    );

    CREATE UNIQUE INDEX ux_readers_email
        ON dbo.readers (email)
        WHERE email IS NOT NULL;

    CREATE UNIQUE INDEX ux_readers_phone
        ON dbo.readers (phone)
        WHERE phone IS NOT NULL;

    CREATE INDEX ix_readers_name
        ON dbo.readers (name);
END;
