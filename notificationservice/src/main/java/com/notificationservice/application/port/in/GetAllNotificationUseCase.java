package com.notificationservice.application.port.in;

import com.notificationservice.application.dto.NotificationSummaryView;
import java.util.List;

public interface GetAllNotificationUseCase {

    List<NotificationSummaryView> get();
}