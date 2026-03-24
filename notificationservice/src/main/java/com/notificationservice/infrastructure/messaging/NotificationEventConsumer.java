package com.notificationservice.infrastructure.messaging;

import com.notificationservice.application.port.in.ProcessNotificationEventUseCase;
import com.notificationservice.application.port.in.DispatchNotificationUseCase; // 1. Add this import
import com.notificationservice.application.port.in.command.SendNotificationCommand;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class NotificationEventConsumer {
    private static final Logger log = LoggerFactory.getLogger(NotificationEventConsumer.class);

    private final ProcessNotificationEventUseCase processEventService;
    private final DispatchNotificationUseCase dispatchUseCase; // 2. Declare the missing use case

    // 3. Update the constructor to inject BOTH
    public NotificationEventConsumer(
            ProcessNotificationEventUseCase processEventService,
            DispatchNotificationUseCase dispatchUseCase
    ) {
        this.processEventService = processEventService;
        this.dispatchUseCase = dispatchUseCase;
    }

    // LISTENER 1: Handles events from other services (Borrow, Reader, etc.)
    @KafkaListener(topics = "notification.events", groupId = "notification-group")
    public void consumeEvent(java.util.Map<String, Object> payload) {
        log.info("Received new notification event from Kafka: {}", payload);
        try {
            String typeStr = (String) payload.get("type");
            String email = (String) payload.get("recipientEmail");

            @SuppressWarnings("unchecked")
            java.util.Map<String, Object> variables = (java.util.Map<String, Object>) payload.get("variables");

            com.notificationservice.domain.model.NotificationType type =
                    com.notificationservice.domain.model.NotificationType.valueOf(typeStr);

            SendNotificationCommand command = new SendNotificationCommand(type, email, variables);
            processEventService.handle(command);
        } catch (Exception e) {
            log.error("Failed to process event", e);
        }
    }
    @KafkaListener(
            topics = "notification.dispatch",
            groupId = "notification-group",
            containerFactory = "stringKafkaListenerContainerFactory"
    )
    public void consumeDispatch(String notificationId) {
        log.info("Processing dispatch for notification ID: {}", notificationId);
        try {
            dispatchUseCase.dispatchFromQueue(notificationId);
        } catch (Exception e) {
            log.error("Failed to dispatch email", e);
        }
    }
}