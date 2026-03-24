# Reader Management Demo

Demo project dùng để minh họa cách tổ chức code theo
Clean Architecture / Hexagonal Architecture với Spring Boot.

## Mục tiêu
- Tách Domain – Application – Infrastructure rõ ràng
- Domain không phụ thuộc Spring / JPA
- Controller chỉ gọi Use Case (Input Port)
- Repository được inject qua Output Port

## Kiến trúc tổng quát

Client  
→ Controller (Web Adapter)  
→ Use Case (Application layer)  
→ Domain  
→ Repository (Infrastructure)

## Cấu trúc package

com.readerservice
├── domain
│   └── model
│       └── Reader
│
├── application
│   ├── port
│   │   ├── in
│   │   └── out
│   ├── service
│   ├── dto
│   └── exception
│
├── infrastructure
│   ├── web
│   ├── persistence
│   └── config

## Lưu ý
- Project này mang tính demo kiến trúc
- Không tập trung vào security, performance
- API thiết kế theo command-based (POST)
