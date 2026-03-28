package com.notificationservice.domain.model;

public enum NotificationType {
    // Reader Events
    READER_CREATED,
    READER_UPDATED,
    READER_SUSPENDED,
    READER_UNSUSPENDED,
    MEMBERSHIP_EXPIRING,
    MEMBERSHIP_EXPIRED,
    READER_DELETED,
    // Borrow Events
    BOOK_BORROWED,
    BOOK_RETURNED,
    BORROWING_EXTENDED,
    BOOK_DUE_SOON,
    BOOK_OVERDUE,
    FINE_GENERATED,
    PAYMENT,

    LOST_BOOK_REPORT,
    CANCEL_SUCCESS
}