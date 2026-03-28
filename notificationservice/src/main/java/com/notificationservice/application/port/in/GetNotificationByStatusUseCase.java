package com.notificationservice.application.port.in;

import com.notificationservice.application.dto.NotificationSummaryView;
import com.notificationservice.domain.model.NotificationStatus;

import java.util.List;

public interface GetNotificationByStatusUseCase {
    List<NotificationSummaryView> getByStatus(NotificationStatus status);
}