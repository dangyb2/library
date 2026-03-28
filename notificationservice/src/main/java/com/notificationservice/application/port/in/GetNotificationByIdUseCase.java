package com.notificationservice.application.port.in;

import com.notificationservice.application.dto.NotificationDetailView;

public interface GetNotificationByIdUseCase {

    NotificationDetailView get(String id);

}