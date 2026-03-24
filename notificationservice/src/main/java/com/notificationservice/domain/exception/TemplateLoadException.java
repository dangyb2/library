package com.notificationservice.domain.exception;

public class TemplateLoadException extends RuntimeException {
    public TemplateLoadException(String templateFile, Throwable cause) {
        super("Failed to load template: " + templateFile, cause);
    }
}
