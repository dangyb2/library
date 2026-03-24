package com.auditservice.domain.model;

import com.auditservice.domain.exception.UnknownEventTypeException;

public enum EventType {
    // Reader events
    READER_CREATED,
    READER_UPDATED,
    READER_SUSPENDED,
    READER_UNSUSPENDED,
    READER_MEMBERSHIP_EXTENDED,

    // Book events
    BOOK_CREATED,
    BOOK_UPDATED,
    BOOK_DELETED,
    BOOK_STOCK_ADDED,
    BOOK_STOCK_REMOVED,
    BOOK_CHECKED_OUT,
    BOOK_RETURNED_TO_STOCK,
    BOOK_RESTORED,

    // Borrow events
    BOOK_BORROWED,
    BOOK_RETURNED,
    BORROW_EXTENDED,
    BORROW_OVERDUE,
    BOOK_REPORTED_LOST,
    BORROW_UPDATED,
    BORROW_CANCELLED,
    BORROW_UNDO_CANCELLED,

    // Payment
    PAYMENT;

    // after=null is valid — nothing exists yet before creation
    public boolean isCreation() {
        return this == READER_CREATED
                || this == BOOK_CREATED
                || this == BOOK_RESTORED;
    }

    // before=null is valid — nothing remains after deletion
    public boolean isDeletion() {
        return this == BOOK_DELETED
                || this == BOOK_REPORTED_LOST;
    }

    // both before and after required — state transition
    public boolean isUpdate() {
        return !isCreation() && !isDeletion();
    }

    public static EventType from(String value) {
        if (value == null || value.isBlank())
            throw new UnknownEventTypeException(value);
        try {
            return EventType.valueOf(value.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new UnknownEventTypeException(value);
        }
    }
}