package com.notificationservice.application.port.out;

public interface EmailSender {
    void send(String recipientEmail, String subject, String content);
}
