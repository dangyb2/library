package com.notificationservice.infrastructure.messaging;

import com.notificationservice.application.port.in.ProcessNotificationEventUseCase;
import com.notificationservice.application.port.in.DispatchNotificationUseCase;
import com.notificationservice.application.port.in.command.SendNotificationCommand;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class NotificationEventConsumer {
    private static final Logger log = LoggerFactory.getLogger(NotificationEventConsumer.class);

    private final ProcessNotificationEventUseCase processEventService;
    private final DispatchNotificationUseCase dispatchUseCase;

    public NotificationEventConsumer(
            ProcessNotificationEventUseCase processEventService,
            DispatchNotificationUseCase dispatchUseCase
    ) {
        this.processEventService = processEventService;
        this.dispatchUseCase = dispatchUseCase;
    }

    @KafkaListener(topics = "notification.events", groupId = "notification-group")
    public void consumeEvent(java.util.Map<String, Object> payload) {
        log.info("Received new notification event from Kafka: {}", payload);

        // 1. Data parsing errors (like missing fields) SHOULD be caught,
        // because retrying a bad payload won't fix it.
        try {
            String typeStr = (String) payload.get("type");
            String email = (String) payload.get("recipientEmail");

            @SuppressWarnings("unchecked")
            java.util.Map<String, Object> variables = (java.util.Map<String, Object>) payload.get("variables");

            com.notificationservice.domain.model.NotificationType type =
                    com.notificationservice.domain.model.NotificationType.valueOf(typeStr);

            SendNotificationCommand command = new SendNotificationCommand(type, email, variables);

            // 2. The actual business logic is executed OUTSIDE the try-catch!
            // If the database fails here, the exception bubbles up, and Kafka will retry it later.
            processEventService.handle(command);

        } catch (IllegalArgumentException | NullPointerException | ClassCastException e) {
            // We only catch data parsing errors here so they don't block the queue forever.
            log.error("Invalid event payload format. Discarding message: {}", payload, e);
        }
    }

    @KafkaListener(
            topics = "notification.dispatch",
            groupId = "notification-group",
            containerFactory = "stringKafkaListenerContainerFactory"
    )
    public void consumeDispatch(String notificationId) {
        log.info("Processing dispatch for notification ID: {}", notificationId);

        // 🚀 NO TRY-CATCH HERE!
        // If sending the email fails, we want this to throw an exception back to Spring
        // so Spring knows the dispatch failed and can utilize its built-in Kafka retry mechanisms.
        dispatchUseCase.dispatchFromQueue(notificationId);
    }
}