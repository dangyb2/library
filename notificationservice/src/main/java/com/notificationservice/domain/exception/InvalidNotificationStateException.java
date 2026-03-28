package com.notificationservice.domain.exception;

public class InvalidNotificationStateException extends RuntimeException {

    public InvalidNotificationStateException(String message) {
        super(message);
    }
}