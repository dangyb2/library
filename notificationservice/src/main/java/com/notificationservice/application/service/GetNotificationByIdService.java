package com.notificationservice.application.service;

import com.notificationservice.application.dto.NotificationDetailView;
import com.notificationservice.application.port.in.GetNotificationByIdUseCase;
import com.notificationservice.application.port.out.NotificationRepository;
import com.notificationservice.domain.exception.NotificationNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class GetNotificationByIdService implements GetNotificationByIdUseCase {

    private final NotificationRepository repository;

    public GetNotificationByIdService(NotificationRepository repository) {
        this.repository = repository;
    }

    @Override
    public NotificationDetailView get(String id) {
        return repository.findById(id)
                .map(NotificationDetailView::fromDomain) // Converts the heavy Domain object to your DTO
                .orElseThrow(() -> new NotificationNotFoundException("Notification not found with ID: " + id));
    }
}