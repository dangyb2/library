package com.auditservice.infrastructure.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
public class KafkaTopicConfig {

    @Bean
    public NewTopic auditEventsTopic() {
        return TopicBuilder.name("audit-events")
                .partitions(3)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic auditEventsDltTopic() {
        return TopicBuilder.name("audit-events.DLT")
                .partitions(3)
                .replicas(1)
                .build();
    }
}