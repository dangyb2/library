package com.notificationservice.infrastructure.email;

import com.notificationservice.domain.exception.TemplateNotFoundException;
import com.notificationservice.domain.model.NotificationType;
import org.springframework.stereotype.Component;

import java.util.Map;

// Make sure your NotificationType enum contains these!
import static com.notificationservice.domain.model.NotificationType.*;
@Component
public class TemplateRegistry {
    private final Map<NotificationType, TemplateDefinition> registry = Map.ofEntries(

            // --- READER SERVICE (Changed .txt to .html to match your folder) ---
            Map.entry(READER_CREATED, new TemplateDefinition("reader-created.html", "Welcome to the library")),
            Map.entry(READER_UPDATED, new TemplateDefinition("reader-updated.html", "Your account was updated")),
            Map.entry(READER_SUSPENDED, new TemplateDefinition("reader-suspended.html", "Your account was suspended")),
            Map.entry(READER_UNSUSPENDED, new TemplateDefinition("reader-unsuspended.html", "Your account was reactivated")),
            Map.entry(MEMBERSHIP_EXPIRING, new TemplateDefinition("membership-expiring.html", "Membership expiring soon")),
            Map.entry(MEMBERSHIP_EXPIRED, new TemplateDefinition("membership-expired.html", "Membership expired")),

            // --- BORROW SERVICE (Now matching your actual filenames) ---
            Map.entry(BOOK_BORROWED, new TemplateDefinition("book-borrowed.html", "Borrow Receipt: {{bookTitle}}")),
            Map.entry(BOOK_RETURNED, new TemplateDefinition("book-returned.html", "Return Confirmation: {{bookTitle}}")),
            Map.entry(BORROWING_EXTENDED, new TemplateDefinition("borrowing-extended.html", "Due Date Extended: {{bookTitle}}")),
            Map.entry(BOOK_OVERDUE, new TemplateDefinition("book-overdue.html", "URGENT: Overdue Notice for {{bookTitle}}")),
            Map.entry(PAYMENT, new TemplateDefinition("payment.html", "Payment Receipt: Thank You")),

            // --- THE NEW EVENTS ---
            Map.entry(LOST_BOOK_REPORT, new TemplateDefinition("lost-book-report.html", "Lost Book Invoice: {{bookTitle}}")),
            Map.entry(CANCEL_SUCCESS, new TemplateDefinition("cancel-success.html", "Reservation Cancelled: {{bookTitle}}"))
    );

    public TemplateDefinition get(NotificationType type) {
        TemplateDefinition definition = registry.get(type);
        if (definition == null) {
            throw new TemplateNotFoundException(type);
        }
        return definition;
    }
}