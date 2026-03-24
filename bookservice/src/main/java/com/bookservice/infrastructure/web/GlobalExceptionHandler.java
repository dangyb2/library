package com.bookservice.infrastructure.web;

import com.bookservice.domain.exception.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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

    @ExceptionHandler(BookNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ApiErrorResponse handleBookNotFoundException(BookNotFoundException ex) {
        return buildError(HttpStatus.NOT_FOUND, ex.getMessage());
    }
    @ExceptionHandler(DuplicateIsbnException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public ApiErrorResponse handleDuplicateIsbnException(DuplicateIsbnException ex) {
        return buildError(HttpStatus.CONFLICT, ex.getMessage());
    }
    @ExceptionHandler(BookCurrentlyBorrowedException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public ApiErrorResponse handleBookCurrentlyBorrowedException(BookCurrentlyBorrowedException ex) {
        return buildError(HttpStatus.CONFLICT, ex.getMessage());
    }
    @ExceptionHandler(InsufficientStockException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiErrorResponse handleInsufficientStockException(InsufficientStockException ex) {
        return buildError(HttpStatus.BAD_REQUEST, ex.getMessage());
    }

    @ExceptionHandler(InvalidBookDataException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiErrorResponse handleInvalidBookDataException(InvalidBookDataException ex) {
        return buildError(HttpStatus.BAD_REQUEST, ex.getMessage());
    }

    @ExceptionHandler(InvalidIsbnException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiErrorResponse handleInvalidIsbnException(InvalidIsbnException ex) {
        return buildError(HttpStatus.BAD_REQUEST, ex.getMessage());
    }
    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    public ApiErrorResponse handleDataIntegrityViolation(org.springframework.dao.DataIntegrityViolationException ex) {
        log.warn("Database integrity violation: {}", ex.getMessage());
        return buildError(HttpStatus.CONFLICT, "A database conflict or constraint violation occurred.");
    }
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleGenericException(Exception ex) {
        // Using the professional logger instead of printStackTrace
        log.error("CRITICAL UNHANDLED EXCEPTION: {}", ex.getMessage(), ex);

        // Using the helper method to keep it clean
        ApiErrorResponse response = buildError(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "An unexpected internal server error occurred: " + ex.getMessage()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}