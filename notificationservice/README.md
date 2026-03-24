# Notification Service

Notification Service nhan event, gui email thong bao va luu lich su email.

## Muc tieu
- Nhan event tu service khac
- Gui email cho doc gia
- Luu lich su email
- Retry neu gui that bai

## Yeu cau
- JDK 25
- SQL Server
- Maven Wrapper (da co trong project)

## Cau hinh DB (SQL Server)
1. Tao database:
```
scripts/sqlserver/create_database.sql
```
2. Cau hinh trong `src/main/resources/application.yml` hoac qua env:
- `DB_URL` (mac dinh: `jdbc:sqlserver://localhost:1433;databaseName=notification_service;encrypt=true;trustServerCertificate=true`)
- `DB_USERNAME` (mac dinh: `sa`)
- `DB_PASSWORD` (mac dinh: `123`)

Flyway se tu dong chay migration tai:
```
src/main/resources/db/migration/sqlserver
```

## Cau hinh mail
Trong `src/main/resources/application.yml` hoac qua env:
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_FROM` (neu can)

## Cau hinh Kafka
- `KAFKA_BOOTSTRAP_SERVERS` (mac dinh: `localhost:9092`)
- `KAFKA_CONSUMER_GROUP` (mac dinh: `notification-service-group`)
- `NOTIFICATION_DISPATCH_TOPIC` (mac dinh: `notification.dispatch`)

## Chay service
```
.\mvnw spring-boot:run
```

## API nhan event
Endpoint:
```
POST /api/notifications/events
```
Body mau:
```
{
  "type": "READER_CREATED",
  "recipientEmail": "user@example.com",
  "variables": {
    "name": "Tran"
  }
}
```

Service luu notification vao DB truoc, sau do publish `notificationId` vao Kafka topic va consumer se thuc hien gui mail.

## API tim kiem notification
1. Tim theo id:
```
GET /api/notifications/{id}
```

2. Tim theo bo loc:
```
GET /api/notifications?id=MAIL-...&email=user@example.com&type=READER_CREATED&status=PENDING&fromDate=2026-03-01T00:00:00Z&toDate=2026-03-31T23:59:59Z
```
Bo loc ho tro:
- `id`
- `email` (tim chua, khong phan biet hoa thuong)
- `type`
- `status`
- `fromDate`, `toDate` (ISO-8601 UTC, inclusive)

## Retry that bai
Retry duoc chay theo lich:
- `notification.retry.delay-ms`
- `notification.retry.max-attempts`
- `notification.retry.batch-size`

## Email templates
Tat ca template nam trong:
```
src/main/resources/templates
```

## Cau truc thu muc
```
Notification Service/
  scripts/sqlserver/
  src/main/java/
  src/main/resources/
  src/main/resources/db/migration/sqlserver/
  src/main/resources/templates/
  pom.xml
  README.md
```
