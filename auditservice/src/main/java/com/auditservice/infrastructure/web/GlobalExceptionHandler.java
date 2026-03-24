package com.auditservice.infrastructure.web;

import com.auditservice.domain.exception.AuditLogNotFoundException;
import com.auditservice.domain.exception.InvalidAuditLogException;
import com.auditservice.domain.exception.UnknownEventTypeException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(InvalidAuditLogException.class)
    public ResponseEntity<ApiErrorResponse> handleInvalid(InvalidAuditLogException ex) {
        return ResponseEntity
                .badRequest()
                .body(new ApiErrorResponse(
                        LocalDateTime.now(),
                        400,
                        "INVALID_AUDIT_LOG",
                        ex.getMessage()
                ));
    }

    @ExceptionHandler(UnknownEventTypeException.class)
    public ResponseEntity<ApiErrorResponse> handleUnknownEventType(UnknownEventTypeException ex) {
        return ResponseEntity
                .badRequest()
                .body(new ApiErrorResponse(
                        LocalDateTime.now(),
                        400,
                        "UNKNOWN_EVENT_TYPE",
                        ex.getMessage()
                ));
    }

    @ExceptionHandler(AuditLogNotFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleNotFound(AuditLogNotFoundException ex) {
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(new ApiErrorResponse(
                        LocalDateTime.now(),
                        404,
                        "AUDIT_LOG_NOT_FOUND",
                        ex.getMessage()
                ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleGeneric() {
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ApiErrorResponse(
                        LocalDateTime.now(),
                        500,
                        "INTERNAL_ERROR",
                        "An unexpected error occurred"
                ));
    }
}