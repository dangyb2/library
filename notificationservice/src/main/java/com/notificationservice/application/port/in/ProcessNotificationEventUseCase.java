package com.notificationservice.application.port.in;

import com.notificationservice.application.port.in.command.SendNotificationCommand;
import com.notificationservice.domain.model.Notification;

public interface ProcessNotificationEventUseCase {
    Notification handle(SendNotificationCommand command);
}
