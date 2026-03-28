package com.notificationservice.infrastructure.web;

import com.notificationservice.application.dto.NotificationDetailView;
import com.notificationservice.application.dto.NotificationSummaryView;
import com.notificationservice.application.port.in.*;
import com.notificationservice.domain.model.NotificationStatus;
import com.notificationservice.domain.model.NotificationType;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/notifications")
public class NotificationEventController {

    private final GetAllNotificationUseCase getAllUseCase;
    private final GetNotificationByIdUseCase getByIdUseCase;
    private final GetNotificationByEmailUseCase getByEmailUseCase;
    private final GetNotificationByTypeUseCase getByTypeUseCase;
    private final GetNotificationByStatusUseCase getByStatusUseCase;
    private final GetNotificationsByDateRangeUseCase getByDateRangeUseCase;
    // 🚀 1. Declare the missing use case field
    private final RetryNotificationUseCase retryUseCase;

    public NotificationEventController(
            GetAllNotificationUseCase getAllUseCase,
            GetNotificationByIdUseCase getByIdUseCase,
            GetNotificationByEmailUseCase getByEmailUseCase,
            GetNotificationByTypeUseCase getByTypeUseCase,
            GetNotificationByStatusUseCase getByStatusUseCase,
            GetNotificationsByDateRangeUseCase getByDateRangeUseCase,
            RetryNotificationUseCase retryUseCase
    ) {
        this.getAllUseCase = getAllUseCase;
        this.getByIdUseCase = getByIdUseCase;
        this.getByEmailUseCase = getByEmailUseCase;
        this.getByTypeUseCase = getByTypeUseCase;
        this.getByStatusUseCase = getByStatusUseCase;
        this.getByDateRangeUseCase = getByDateRangeUseCase;
        this.retryUseCase = retryUseCase;
    }

    @GetMapping
    public ResponseEntity<List<NotificationSummaryView>> getAllNotifications() {
        return ResponseEntity.ok(getAllUseCase.get());
    }

    @GetMapping("/{id}")
    public ResponseEntity<NotificationDetailView> getNotificationById(@PathVariable String id) {
        return ResponseEntity.ok(getByIdUseCase.get(id));
    }

    @GetMapping("/reader/{email}")
    public ResponseEntity<List<NotificationSummaryView>> getNotificationsByEmail(@PathVariable String email) {
        return ResponseEntity.ok(getByEmailUseCase.getByEmail(email));
    }

    @GetMapping("/type/{type}")
    public ResponseEntity<List<NotificationSummaryView>> getNotificationsByType(@PathVariable NotificationType type) {
        return ResponseEntity.ok(getByTypeUseCase.getByType(type));
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<List<NotificationSummaryView>> getNotificationsByStatus(@PathVariable NotificationStatus status) {
        return ResponseEntity.ok(getByStatusUseCase.getByStatus(status));
    }

    @GetMapping("/dates")
    public ResponseEntity<List<NotificationSummaryView>> getNotificationsByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to
    ) {
        return ResponseEntity.ok(getByDateRangeUseCase.getByDateRange(from, to));
    }

    @PostMapping("/{id}/retry")
    public ResponseEntity<Void> retry(@PathVariable String id) {
        retryUseCase.retry(id);
        return ResponseEntity.accepted().build();
    }
}