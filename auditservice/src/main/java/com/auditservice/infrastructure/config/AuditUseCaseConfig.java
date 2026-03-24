package com.auditservice.infrastructure.config;

import com.auditservice.application.port.in.*;
import com.auditservice.application.port.out.AuditLogRepository;
import com.auditservice.application.port.out.DeadLetterQueuePort;
import com.auditservice.application.service.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// infrastructure/config/AuditUseCaseConfig.java
@Configuration
public class AuditUseCaseConfig {

    @Bean
    public RecordAuditLogUseCase recordAuditLogUseCase(AuditLogRepository repository) {
        return new RecordAuditLogService(repository);
    }

    @Bean
    public GetAllAuditLogsUseCase getAllAuditLogsUseCase(AuditLogRepository repository) {
        return new GetAllAuditLogsService(repository);
    }

    @Bean
    public GetAuditLogByIdUseCase getAuditLogByIdUseCase(AuditLogRepository repository) {
        return new GetAuditLogByIdService(repository);
    }

    @Bean
    public GetAuditLogsByAggregateIdUseCase getAuditLogsByAggregateUseCase(AuditLogRepository repository) {
        return new GetAuditLogsByAggregateIdService(repository);
    }

    @Bean
    public GetAuditLogsByEventTypeUseCase getAuditLogsByEventTypeUseCase(AuditLogRepository repository) {
        return new GetAuditLogsByEventTypeService(repository);
    }

    @Bean
    public GetAuditLogsByDateRangeUseCase getAuditLogsByDateRangeUseCase(AuditLogRepository repository) {
        return new GetAuditLogsByDateRangeService(repository);
    }
    @Bean
    public ReplayDeadLetterQueueUseCase replayDeadLetterQueueUseCase(DeadLetterQueuePort deadLetterQueuePort) {
        return new ReplayDeadLetterQueueService(deadLetterQueuePort);
    }
}