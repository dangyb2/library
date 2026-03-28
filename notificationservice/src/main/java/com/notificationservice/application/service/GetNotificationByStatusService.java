package com.notificationservice.application.service;

import com.notificationservice.application.dto.NotificationSummaryView;
import com.notificationservice.application.port.in.GetNotificationByStatusUseCase;
import com.notificationservice.application.port.out.NotificationRepository;
import com.notificationservice.domain.model.NotificationStatus;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class GetNotificationByStatusService implements GetNotificationByStatusUseCase {

    private final NotificationRepository repository;

    public GetNotificationByStatusService(NotificationRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<NotificationSummaryView> getByStatus(NotificationStatus status) {
        return repository.findByStatus(status).stream()
                .map(NotificationSummaryView::fromDomain)
                .toList();
    }
}