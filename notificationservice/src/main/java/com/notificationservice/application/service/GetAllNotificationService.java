package com.notificationservice.application.service;

import com.notificationservice.application.dto.NotificationSummaryView;
import com.notificationservice.application.port.in.GetAllNotificationUseCase;
import com.notificationservice.application.port.out.NotificationRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class GetAllNotificationService implements GetAllNotificationUseCase {
    private final NotificationRepository repository;

    public GetAllNotificationService(NotificationRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<NotificationSummaryView> get() {
        return repository.findAll().stream()
                .map(NotificationSummaryView::fromDomain)
                .toList();
    }
}