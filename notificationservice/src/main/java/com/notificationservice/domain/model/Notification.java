package com.notificationservice.domain.model;

import com.notificationservice.domain.exception.InvalidNotificationStateException;

import java.time.Instant;
import java.util.Objects;

public class Notification {
    private final String id;
    private final String recipientEmail;
    private final NotificationType type;
    private final String subject;
    private final String content;
    private NotificationStatus status;
    private int retryCount;
    private final Instant createdAt;
    private Instant sentAt;

    private Notification(
            String id,
            String recipientEmail,
            NotificationType type,
            String subject,
            String content,
            NotificationStatus status,
            int retryCount,
            Instant createdAt,
            Instant sentAt
    ) {
        this.id = Objects.requireNonNull(id, "id");
        this.recipientEmail = Objects.requireNonNull(recipientEmail, "recipientEmail");
        this.type = Objects.requireNonNull(type, "type");
        this.subject = Objects.requireNonNull(subject, "subject");
        this.content = Objects.requireNonNull(content, "content");
        this.status = Objects.requireNonNull(status, "status");
        this.retryCount = retryCount;
        this.createdAt = Objects.requireNonNull(createdAt, "createdAt");
        this.sentAt = sentAt;
    }

    public static Notification pending(
            String id,
            String recipientEmail,
            NotificationType type,
            String subject,
            String content,
            Instant createdAt
    ) {
        return new Notification(
                id,
                recipientEmail,
                type,
                subject,
                content,
                NotificationStatus.PENDING,
                0,
                createdAt,
                null
        );
    }

    public static Notification restore(
            String id,
            String recipientEmail,
            NotificationType type,
            String subject,
            String content,
            NotificationStatus status,
            int retryCount,
            Instant createdAt,
            Instant sentAt
    ) {
        return new Notification(
                id,
                recipientEmail,
                type,
                subject,
                content,
                status,
                retryCount,
                createdAt,
                sentAt
        );
    }

    public void markSent(Instant sentAt) {
        if (this.status == NotificationStatus.SENT) {
            // 🚀 Use your new custom Domain Exception!
            throw new InvalidNotificationStateException("Cannot mark as sent: Notification is already in SENT status.");
        }
        this.status = NotificationStatus.SENT;
        this.sentAt = sentAt;
    }
    public void markFailed() {
        if (this.status == NotificationStatus.SENT) {
            throw new InvalidNotificationStateException("Cannot fail a notification that has already been sent.");
        }
        this.status = NotificationStatus.FAILED;
    }
    public void incrementRetry() {
        this.retryCount += 1;
    }

    public String getId() {
        return id;
    }

    public String getRecipientEmail() {
        return recipientEmail;
    }

    public NotificationType getType() {
        return type;
    }

    public String getSubject() {
        return subject;
    }

    public String getContent() {
        return content;
    }

    public NotificationStatus getStatus() {
        return status;
    }

    public int getRetryCount() {
        return retryCount;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getSentAt() {
        return sentAt;
    }
}
