package com.notificationservice.application.service;

import com.notificationservice.domain.exception.InvalidDateRangeException;
import com.notificationservice.domain.exception.NotificationNotFoundException;
import com.notificationservice.application.port.in.SearchNotificationsUseCase;
import com.notificationservice.application.port.in.query.NotificationSearchQuery;
import com.notificationservice.application.port.out.NotificationRepository;
import com.notificationservice.domain.model.Notification;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service
public class SearchNotificationsService implements SearchNotificationsUseCase {
    private final NotificationRepository notificationRepository;

    public SearchNotificationsService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @Override
    public Notification findById(String id) {
        return notificationRepository.findById(id)
                .orElseThrow(() -> new NotificationNotFoundException(id));
    }

    @Override
    public List<Notification> search(NotificationSearchQuery query) {
        validateDateRange(query.fromDate(), query.toDate());
        return notificationRepository.search(
                clean(query.id()),
                clean(query.recipientEmail()),
                query.type(),
                query.status(),
                query.fromDate(),
                query.toDate()
        );
    }

    private void validateDateRange(Instant fromDate, Instant toDate) {
        if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
            throw new InvalidDateRangeException(fromDate, toDate);
        }
    }

    private String clean(String input) {
        if (input == null) {
            return null;
        }
        String trimmed = input.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
