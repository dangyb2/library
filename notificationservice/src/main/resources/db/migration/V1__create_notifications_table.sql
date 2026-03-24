create table if not exists notifications (
    id varchar(50) not null primary key,
    recipient_email varchar(255) not null,
    type varchar(40) not null,
    subject varchar(200) not null,
    content clob not null,
    status varchar(20) not null,
    retry_count integer not null,
    created_at timestamp not null,
    sent_at timestamp null
);

create index if not exists idx_notifications_status_retry_created
    on notifications (status, retry_count, created_at);
