package com.auditservice.infrastructure.messaging;

import com.auditservice.application.port.out.DeadLetterQueuePort;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

@Component
public class KafkaDltAdapter implements DeadLetterQueuePort {

    private final ConsumerFactory<String, Object> consumerFactory;
    private final KafkaTemplate<String, Object> kafkaTemplate;

    private static final String DLT_TOPIC = "audit-events.DLT";
    private static final String MAIN_TOPIC = "audit-events";

    public KafkaDltAdapter(ConsumerFactory<String, Object> consumerFactory, KafkaTemplate<String, Object> kafkaTemplate) {
        this.consumerFactory = consumerFactory;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Override
    public int replayMessages() {
        int replayedCount = 0;

        // 1. Grab the configuration directly from the Spring-injected factory
        Map<String, Object> props = new HashMap<>(
                ((DefaultKafkaConsumerFactory<String, Object>) consumerFactory).getConfigurationProperties()
        );

        // 2. FORCE it to start from the beginning!
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        // 3. Create a fresh factory with these new rules
        DefaultKafkaConsumerFactory<String, Object> manualFactory = new DefaultKafkaConsumerFactory<>(props);

        // 4. Create the consumer
        try (Consumer<String, Object> consumer = manualFactory.createConsumer("dlt-replayer-group", null)) {
            consumer.subscribe(Collections.singletonList(DLT_TOPIC));

            // Poll Kafka for exactly 3 seconds
            ConsumerRecords<String, Object> records = consumer.poll(Duration.ofSeconds(3));

            for (ConsumerRecord<String, Object> record : records) {
                // Shoot the message right back into the main topic
                kafkaTemplate.send(MAIN_TOPIC, record.key(), record.value());
                replayedCount++;
            }

            // Tell Kafka we successfully processed them so they drop out of the DLT
            consumer.commitSync();

        } catch (Exception e) {
            System.err.println("Failed to replay DLT messages: " + e.getMessage());
        }

        return replayedCount;
    }
}