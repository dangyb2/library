package com.notificationservice.application.service;

import com.notificationservice.application.dto.NotificationSummaryView;
import com.notificationservice.application.port.in.GetNotificationByTypeUseCase;
import com.notificationservice.application.port.out.NotificationRepository;
import com.notificationservice.domain.model.NotificationType;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class GetNotificationByTypeService implements GetNotificationByTypeUseCase {

    private final NotificationRepository repository;

    public GetNotificationByTypeService(NotificationRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<NotificationSummaryView> getByType(NotificationType type) {
        return repository.findByType(type).stream()
                .map(NotificationSummaryView::fromDomain)
                .toList();
    }
}