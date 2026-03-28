package com.notificationservice.application.service;

import com.notificationservice.application.dto.NotificationSummaryView;
import com.notificationservice.application.port.in.GetNotificationByEmailUseCase;
import com.notificationservice.application.port.out.NotificationRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class GetNotificationByEmailService implements GetNotificationByEmailUseCase {

    private final NotificationRepository repository;

    public GetNotificationByEmailService(NotificationRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<NotificationSummaryView> getByEmail(String email) {
        return repository.findByRecipientEmail(email).stream()
                .map(NotificationSummaryView::fromDomain)
                .toList();
    }
}