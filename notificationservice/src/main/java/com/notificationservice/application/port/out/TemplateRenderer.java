package com.notificationservice.application.port.out;

import com.notificationservice.application.service.RenderedEmail;
import com.notificationservice.domain.model.NotificationType;

import java.util.Map;

public interface TemplateRenderer {
    RenderedEmail render(NotificationType type, Map<String, Object> variables);
}
