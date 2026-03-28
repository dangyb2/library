package com.notificationservice.application.service;

import com.notificationservice.application.dto.NotificationSummaryView;
import com.notificationservice.application.port.in.GetNotificationsByDateRangeUseCase;
import com.notificationservice.application.port.out.NotificationRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service
public class GetNotificationsByDateRangeService implements GetNotificationsByDateRangeUseCase {

    private final NotificationRepository repository;

    public GetNotificationsByDateRangeService(NotificationRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<NotificationSummaryView> getByDateRange(Instant startDate, Instant endDate) {
        // Basic validation so we don't accidentally query backward in time!
        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("Start date must be before end date");
        }

        return repository.findByDateRange(startDate, endDate).stream()
                .map(NotificationSummaryView::fromDomain)
                .toList();
    }
}