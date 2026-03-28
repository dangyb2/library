package com.notificationservice.application.service;

import com.notificationservice.application.port.in.ProcessNotificationEventUseCase;
import com.notificationservice.application.port.in.command.SendNotificationCommand;
import com.notificationservice.application.port.out.NotificationDispatchPublisher;
import com.notificationservice.application.port.out.NotificationRepository;
import com.notificationservice.application.port.out.TemplateRenderer;
import com.notificationservice.application.util.NotificationIdGenerator;
import com.notificationservice.application.util.RenderedEmail;
import com.notificationservice.domain.model.Notification;
import org.springframework.stereotype.Service;

import java.time.Clock;

@Service
public class ProcessNotificationEventService implements ProcessNotificationEventUseCase {
    private final NotificationRepository notificationRepository;
    private final TemplateRenderer templateRenderer;
    private final NotificationIdGenerator idGenerator;
    private final NotificationDispatchPublisher dispatchPublisher;
    private final Clock clock;

    public ProcessNotificationEventService(
            NotificationRepository notificationRepository,
            TemplateRenderer templateRenderer,
            NotificationIdGenerator idGenerator,
            NotificationDispatchPublisher dispatchPublisher,
            Clock clock
    ) {
        this.notificationRepository = notificationRepository;
        this.templateRenderer = templateRenderer;
        this.idGenerator = idGenerator;
        this.dispatchPublisher = dispatchPublisher;
        this.clock = clock;
    }

    @Override
    public Notification handle(SendNotificationCommand command) {
        RenderedEmail rendered = templateRenderer.render(command.type(), command.variables());
        Notification notification = Notification.pending(
                idGenerator.newId(),
                command.recipientEmail(),
                command.type(),
                rendered.subject(),
                rendered.content(),
                clock.instant()
        );

        Notification saved = notificationRepository.save(notification);
        dispatchPublisher.publish(saved.getId());
        return saved;
    }
}
