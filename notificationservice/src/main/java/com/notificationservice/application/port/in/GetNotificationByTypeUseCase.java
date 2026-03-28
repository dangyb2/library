package com.notificationservice.application.port.in;

import com.notificationservice.application.dto.NotificationSummaryView;
import com.notificationservice.domain.model.NotificationType;

import java.util.List;

public interface GetNotificationByTypeUseCase {
    List<NotificationSummaryView> getByType(NotificationType type);
}