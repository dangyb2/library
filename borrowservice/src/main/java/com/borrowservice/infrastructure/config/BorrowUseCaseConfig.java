package com.borrowservice.infrastructure.config;

import com.borrowservice.application.port.in.*;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.NotificationPort; // <-- 1. Import NotificationPort
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.application.service.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class BorrowUseCaseConfig {

    @Bean
    public ListAllBorrowsUseCase listAllBorrowsUseCase(
            BookBorrowRepository bookBorrowRepository,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        return new ListAllBorrowsService(bookBorrowRepository, bookCatalogPort, readerRegistryPort);
    }

    // --> UPDATED TO INJECT NOTIFICATION PORT
    @Bean
    public BorrowBookUseCase borrowBookUseCase(
            BookBorrowRepository bookBorrowRepository,
            ReaderRegistryPort readerRegistryPort,
            BookCatalogPort bookCatalogPort,
            AuditMessagePort auditMessagePort,
            NotificationPort notificationPort // <-- Added
    ) {
        return new BorrowBookService(bookBorrowRepository, readerRegistryPort, bookCatalogPort, auditMessagePort, notificationPort); // <-- Passed
    }

    @Bean
    public ReturnBookUseCase returnBookUseCase(
            BookBorrowRepository bookBorrowRepository,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort,
            AuditMessagePort auditMessagePort,
            NotificationPort notificationPort
    ) {
        return new ReturnBookService(bookBorrowRepository, bookCatalogPort, readerRegistryPort, auditMessagePort, notificationPort); // <-- Pass here
    }

    @Bean
    public ExtendBorrowTimeUseCase extendBorrowTimeUseCase(
            BookBorrowRepository bookBorrowRepository,
            AuditMessagePort auditMessagePort,
            NotificationPort notificationPort,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        return new ExtendBorrowTimeService(
                bookBorrowRepository,
                auditMessagePort,
                notificationPort,
                bookCatalogPort,
                readerRegistryPort
        );
    }

    @Bean
    public PaymentUseCase payFineUseCase(
            BookBorrowRepository bookBorrowRepository,
            AuditMessagePort auditMessagePort,
            NotificationPort notificationPort,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        return new PaymentService(
                bookBorrowRepository,
                auditMessagePort,
                notificationPort,
                bookCatalogPort,
                readerRegistryPort
        );
    }
    @Bean
    public ReturnBookPreviewUseCase returnBookPreviewUseCase(
            BookBorrowRepository bookBorrowRepository,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        return new ReturnBookPreviewService(bookBorrowRepository, bookCatalogPort, readerRegistryPort);
    }

    @Bean
    public ReportBookLostUseCase reportBookLostUseCase(
            BookBorrowRepository bookBorrowRepository,
            AuditMessagePort auditMessagePort,
            NotificationPort notificationPort, // <-- Added
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        return new ReportBookLostService(
                bookBorrowRepository,
                auditMessagePort,
                notificationPort,
                bookCatalogPort,
                readerRegistryPort
        );
    }

    @Bean
    public FoundLostBookUseCase foundLostBookUseCase(
            BookBorrowRepository bookBorrowRepository,
            AuditMessagePort auditMessagePort,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        return new FoundLostBookService(
                bookBorrowRepository,
                auditMessagePort,
                bookCatalogPort,
                readerRegistryPort
        );
    }

    @Bean
    public GetBorrowDetailsUseCase getBorrowDetailsUseCase(
            BookBorrowRepository bookBorrowRepository,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        return new GetBorrowDetailsService(bookBorrowRepository, bookCatalogPort, readerRegistryPort);
    }

    @Bean
    public GetOverdueBorrowsUseCase getOverdueBorrowsUseCase(BookBorrowRepository bookBorrowRepository) {
        return new GetOverdueBorrowsService(bookBorrowRepository);
    }

    @Bean
    public ListReaderBorrowsQuery listReaderBorrowsQuery(
            BookBorrowRepository bookBorrowRepository,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        return new ListReaderBorrowsService(bookBorrowRepository, bookCatalogPort, readerRegistryPort);
    }

    @Bean
    public MarkOverdueBorrowsUseCase markOverdueBorrowsUseCase(
            BookBorrowRepository bookBorrowRepository,
            AuditMessagePort auditMessagePort,
            NotificationPort notificationPort,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort
    ) {
        return new MarkOverdueBorrowsService(bookBorrowRepository, auditMessagePort, notificationPort, bookCatalogPort, readerRegistryPort);
    }

    @Bean
    public UpdateBorrowUseCase updateBorrowUseCase(
            BookBorrowRepository repository,
            AuditMessagePort auditMessagePort,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        return new UpdateBorrowService(repository, auditMessagePort, bookCatalogPort, readerRegistryPort);
    }

    @Bean
    public CancelBorrowUseCase cancelBorrowUseCase(
            BookBorrowRepository bookBorrowRepository,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort,
            AuditMessagePort auditMessagePort,
            NotificationPort notificationPort // <-- Added
    ) {
        return new CancelBorrowService(
                bookBorrowRepository,
                bookCatalogPort,
                readerRegistryPort,
                auditMessagePort,
                notificationPort
        );
    }

    @Bean
    public UndoCancelBorrowUseCase undoCancelBorrowUseCase(
            BookBorrowRepository bookBorrowRepository,
            BookCatalogPort bookCatalogPort,
            AuditMessagePort auditMessagePort) {
        return new UndoCancelBorrowService(bookBorrowRepository, bookCatalogPort, auditMessagePort);
    }
    @Bean
    public RemindApproachingDueDateUseCase remindApproachingDueDateUseCase(
            BookBorrowRepository bookBorrowRepository,
            NotificationPort notificationPort,
            ReaderRegistryPort readerRegistryPort) {
        return new RemindApproachingDueDateService(
                bookBorrowRepository,
                notificationPort,
                readerRegistryPort
        );
    }
    @Bean
    CheckActiveBorrowsUseCase checkActiveBorrowsUseCase(BookBorrowRepository repository) {
        return new CheckActiveBorrowsService(repository);
    }

}