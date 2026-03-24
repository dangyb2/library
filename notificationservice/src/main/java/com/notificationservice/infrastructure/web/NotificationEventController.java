package com.notificationservice.infrastructure.web;

import com.notificationservice.application.port.in.ProcessNotificationEventUseCase;
import com.notificationservice.application.port.in.SearchNotificationsUseCase;
import com.notificationservice.application.port.in.query.NotificationSearchQuery;
import com.notificationservice.application.port.in.command.SendNotificationCommand;
import com.notificationservice.domain.model.Notification;
import com.notificationservice.domain.model.NotificationStatus;
import com.notificationservice.domain.model.NotificationType;
import com.notificationservice.infrastructure.dto.NotificationDetailsResponse;
import com.notificationservice.infrastructure.dto.NotificationEventRequest;
import com.notificationservice.infrastructure.dto.NotificationEventResponse;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class NotificationEventController {
    private final ProcessNotificationEventUseCase processUseCase;
    private final SearchNotificationsUseCase searchUseCase;

    public NotificationEventController(
            ProcessNotificationEventUseCase processUseCase,
            SearchNotificationsUseCase searchUseCase
    ) {
        this.processUseCase = processUseCase;
        this.searchUseCase = searchUseCase;
    }

    @PostMapping("/events")
    public ResponseEntity<NotificationEventResponse> handle(@Valid @RequestBody NotificationEventRequest request) {
        SendNotificationCommand command = new SendNotificationCommand(
                request.type(),
                request.recipientEmail(),
                request.variables()
        );
        Notification notification = processUseCase.handle(command);
        NotificationEventResponse response = new NotificationEventResponse(
                notification.getId(),
                notification.getStatus(),
                notification.getRetryCount(),
                notification.getSentAt()
        );
        return ResponseEntity.accepted().body(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<NotificationDetailsResponse> findById(@PathVariable String id) {
        Notification notification = searchUseCase.findById(id);
        return ResponseEntity.ok(toDetailsResponse(notification));
    }

    @GetMapping
    public ResponseEntity<List<NotificationDetailsResponse>> search(
            @RequestParam(required = false) String id,
            @RequestParam(name = "email", required = false) String recipientEmail,
            @RequestParam(required = false) NotificationType type,
            @RequestParam(required = false) NotificationStatus status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant fromDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant toDate
    ) {
        NotificationSearchQuery query = new NotificationSearchQuery(
                id,
                recipientEmail,
                type,
                status,
                fromDate,
                toDate
        );
        List<NotificationDetailsResponse> response = searchUseCase.search(query)
                .stream()
                .map(this::toDetailsResponse)
                .toList();
        return ResponseEntity.ok(response);
    }

    private NotificationDetailsResponse toDetailsResponse(Notification notification) {
        return new NotificationDetailsResponse(
                notification.getId(),
                notification.getRecipientEmail(),
                notification.getType(),
                notification.getStatus(),
                notification.getRetryCount(),
                notification.getCreatedAt(),
                notification.getSentAt()
        );
    }
}
