package com.borrowservice.application.service;

import com.borrowservice.application.port.in.RemindApproachingDueDateUseCase;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.NotificationPort;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.model.Borrow;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class RemindApproachingDueDateService implements RemindApproachingDueDateUseCase {

    private final BookBorrowRepository borrowRepository;
    private final NotificationPort notificationPort;
    private final ReaderRegistryPort readerRegistryPort;

    public RemindApproachingDueDateService(
            BookBorrowRepository borrowRepository,
            NotificationPort notificationPort,
            ReaderRegistryPort readerRegistryPort) {
        this.borrowRepository = borrowRepository;
        this.notificationPort = notificationPort;
        this.readerRegistryPort = readerRegistryPort;
    }

    @Override
    public void sendReminders() {
        // 1. Target books due exactly 2 days from today
        LocalDate targetDate = LocalDate.now().plusDays(3);
        List<Borrow> borrowsDueSoon = borrowRepository.findBorrowsDueOn(targetDate);

        for (Borrow borrow : borrowsDueSoon) {

            // 2. Fetch the actual reader's email using your port
            String recipientEmail = readerRegistryPort.getReaderEmail(borrow.getReaderId());

            // 3. Package the variables for your Kafka Notification Service
            Map<String, Object> variables = new HashMap<>();
            variables.put("bookId", borrow.getBookId());
            variables.put("borrowId", borrow.getBorrowId());
            variables.put("dueDate", borrow.getDueDate().toString());

            // 4. Send the event!
            notificationPort.sendNotification(
                    "BOOK_DUE_SOON",
                    recipientEmail,
                    variables
            );
        }

        System.out.println("Published " + borrowsDueSoon.size() + " BOOK_DUE_SOON events to Kafka.");
    }
}