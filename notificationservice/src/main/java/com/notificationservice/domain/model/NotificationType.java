package com.notificationservice.domain.model;

public enum NotificationType {
    // Reader Events
    READER_CREATED,
    READER_UPDATED,
    READER_SUSPENDED,
    READER_UNSUSPENDED,
    MEMBERSHIP_EXPIRING,
    MEMBERSHIP_EXPIRED,

    // Borrow Events
    BOOK_BORROWED,
    BOOK_RETURNED,
    BORROWING_EXTENDED,
    BOOK_DUE_SOON,
    BOOK_OVERDUE,
    FINE_GENERATED,
    PAYMENT,

    // NEW Events we added today
    LOST_BOOK_REPORT,
    CANCEL_SUCCESS
}