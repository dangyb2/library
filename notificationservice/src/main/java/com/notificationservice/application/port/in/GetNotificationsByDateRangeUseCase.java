package com.notificationservice.application.port.in;

import com.notificationservice.application.dto.NotificationSummaryView;
import java.time.Instant;
import java.util.List;

public interface GetNotificationsByDateRangeUseCase {
    List<NotificationSummaryView> getByDateRange(Instant startDate, Instant endDate);
}