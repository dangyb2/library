package com.borrowservice.infrastructure.web;

import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import com.borrowservice.domain.exception.BorrowDomainException; // Imported the new base
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    private ApiErrorResponse buildError(HttpStatus status, String message) {
        return new ApiErrorResponse(
                LocalDateTime.now(),
                status.value(),
                status.getReasonPhrase(),
                message
        );
    }

    @ExceptionHandler(BorrowRecordNotFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleNotFound(BorrowRecordNotFoundException ex) {
        ApiErrorResponse response = buildError(HttpStatus.NOT_FOUND, ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    /**
     * Catches ALL domain-specific business rule violations.
     * Examples: BorrowLimitExceededException, BookNotAvailableException, etc.
     */
    @ExceptionHandler(BorrowDomainException.class)
    public ResponseEntity<ApiErrorResponse> handleDomainExceptions(BorrowDomainException ex) {
        log.warn("Domain rule violation: {}", ex.getMessage());

        // 400 BAD_REQUEST or 422 UNPROCESSABLE_ENTITY are standard here.
        ApiErrorResponse response = buildError(HttpStatus.BAD_REQUEST, ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    /**
     * Fallback for any other unexpected 500 Internal Server Errors.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleGenericException(Exception ex) {
        log.error("CRITICAL UNHANDLED EXCEPTION: {}", ex.getMessage(), ex);

        ApiErrorResponse response = buildError(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "An unexpected internal server error occurred: " + ex.getMessage()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}