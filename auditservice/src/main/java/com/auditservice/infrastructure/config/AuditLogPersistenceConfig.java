package com.auditservice.infrastructure.config;

import com.auditservice.application.port.out.AuditLogRepository;
import com.auditservice.infrastructure.persistence.JpaAuditLogRepository;
import com.auditservice.infrastructure.persistence.SpringDataAuditLogRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AuditLogPersistenceConfig {
    @Bean
    AuditLogRepository auditLogRepository(SpringDataAuditLogRepository jpaRepos) {
        return new JpaAuditLogRepository(jpaRepos);
    }
}
