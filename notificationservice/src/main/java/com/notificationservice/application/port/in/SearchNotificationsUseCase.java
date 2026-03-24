package com.notificationservice.application.port.in;

import com.notificationservice.application.port.in.query.NotificationSearchQuery;
import com.notificationservice.domain.model.Notification;

import java.util.List;

public interface SearchNotificationsUseCase {
    Notification findById(String id);

    List<Notification> search(NotificationSearchQuery query);
}
