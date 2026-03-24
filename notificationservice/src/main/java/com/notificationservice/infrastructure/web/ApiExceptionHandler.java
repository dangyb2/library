package com.notificationservice.infrastructure.web;

import com.notificationservice.domain.exception.InvalidDateRangeException;
import com.notificationservice.domain.exception.NotificationNotFoundException;
import com.notificationservice.domain.exception.NotificationPublishException;
import com.notificationservice.domain.exception.TemplateLoadException;
import com.notificationservice.domain.exception.TemplateNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.time.LocalDateTime;
import java.util.stream.Collectors;

@RestControllerAdvice
public class ApiExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(this::formatFieldError)
                .collect(Collectors.joining(", "));
        return build(HttpStatus.BAD_REQUEST, message, ex);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiErrorResponse> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        String message = "Invalid value for parameter '" + ex.getName() + "'";
        return build(HttpStatus.BAD_REQUEST, message, ex);
    }

    @ExceptionHandler(InvalidDateRangeException.class)
    public ResponseEntity<ApiErrorResponse> handleInvalidDateRange(InvalidDateRangeException ex) {
        return build(HttpStatus.BAD_REQUEST, safeMessage(ex), ex);
    }

    @ExceptionHandler(TemplateNotFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleTemplateNotFound(TemplateNotFoundException ex) {
        return build(HttpStatus.BAD_REQUEST, safeMessage(ex), ex);
    }

    @ExceptionHandler(TemplateLoadException.class)
    public ResponseEntity<ApiErrorResponse> handleTemplateLoad(TemplateLoadException ex) {
        return build(HttpStatus.INTERNAL_SERVER_ERROR, safeMessage(ex), ex);
    }

    @ExceptionHandler(NotificationNotFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleNotificationNotFound(NotificationNotFoundException ex) {
        return build(HttpStatus.NOT_FOUND, safeMessage(ex), ex);
    }

    @ExceptionHandler(NotificationPublishException.class)
    public ResponseEntity<ApiErrorResponse> handlePublishFailure(NotificationPublishException ex) {
        return build(HttpStatus.SERVICE_UNAVAILABLE, "Failed to queue notification for dispatch", ex);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiErrorResponse> handleIllegalArgument(IllegalArgumentException ex) {
        return build(HttpStatus.BAD_REQUEST, safeMessage(ex), ex);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleUnexpected(Exception ex) {
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "Unexpected error", ex);
    }

    private String formatFieldError(FieldError error) {
        return error.getField() + ": " + error.getDefaultMessage();
    }

    private String safeMessage(Throwable ex) {
        String message = ex.getMessage();
        return message == null || message.isBlank() ? "Bad request" : message;
    }

    private ResponseEntity<ApiErrorResponse> build(HttpStatus status, String message) {
        return build(status, message, null);
    }

    private ResponseEntity<ApiErrorResponse> build(HttpStatus status, String message, Exception ex) {
        if (ex != null) {
            if (status.is5xxServerError()) {
                log.error("Unhandled exception", ex);
            } else {
                log.warn("Request failed: {}", message, ex);
            }
        }
        ApiErrorResponse body = new ApiErrorResponse(
                LocalDateTime.now(),
                status.value(),
                status.getReasonPhrase(),
                message
        );
        return ResponseEntity.status(status).body(body);
    }
}
