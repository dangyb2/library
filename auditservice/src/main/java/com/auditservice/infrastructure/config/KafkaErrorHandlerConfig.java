package com.auditservice.infrastructure.config;

import com.auditservice.domain.exception.InvalidAuditLogException;
import com.auditservice.domain.exception.UnknownEventTypeException;
import org.springframework.kafka.support.serializer.JsonSerializer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.TopicPartition;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.FixedBackOff;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class KafkaErrorHandlerConfig {

    private static final Logger log = LoggerFactory.getLogger(KafkaErrorHandlerConfig.class);

    @Bean
    public DefaultErrorHandler errorHandler(KafkaTemplate<String, Object> dltKafkaTemplate) {

        DeadLetterPublishingRecoverer recoverer = new DeadLetterPublishingRecoverer(
                dltKafkaTemplate,
                (record, ex) -> {
                    log.error("Publishing to DLT — topic={} offset={} reason={}",
                            record.topic(), record.offset(), ex.getMessage());
                    return new TopicPartition(record.topic() + ".DLT", record.partition());
                }
        );

        FixedBackOff backOff = new FixedBackOff(2000L, 3L);
        DefaultErrorHandler handler = new DefaultErrorHandler(recoverer, backOff);
        handler.addNotRetryableExceptions(
                InvalidAuditLogException.class,
                UnknownEventTypeException.class
        );
        return handler;
    }

    @Bean
    public KafkaTemplate<String, Object> dltKafkaTemplate(
            ProducerFactory<String, Object> producerFactory) {

        Map<String, Object> props = new HashMap<>(producerFactory.getConfigurationProperties());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);

        return new KafkaTemplate<>(new DefaultKafkaProducerFactory<>(props));
    }
}