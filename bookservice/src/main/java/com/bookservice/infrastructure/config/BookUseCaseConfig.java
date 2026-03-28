package com.bookservice.infrastructure.config;

import com.bookservice.application.port.in.*;
import com.bookservice.application.port.out.AiGenrePredictorPort;
import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.application.service.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class BookUseCaseConfig {
    @Bean
    AddBookStockUseCase addBookStockUseCase(BookRepository bookRepository, AuditMessagePort auditMessagePort) {
        return new AddBookStockService(bookRepository,auditMessagePort);
    }

    @Bean
    CreateBookUseCase createBookUseCase(BookRepository bookRepository, AuditMessagePort auditMessagePort) {
        return new CreateBookService(bookRepository, auditMessagePort);
    }
    @Bean
    CheckoutBookUseCase decreaseBookStockUseCase(BookRepository bookRepository, AuditMessagePort auditMessagePort) {
        return new CheckoutBookService(bookRepository,auditMessagePort);
    }
    @Bean
    public GetBookTitlesBatchUseCase getBookTitlesBatchUseCase(BookRepository bookRepository) {
        return new GetBookTitlesBatchService(bookRepository);
    }
    @Bean
    DecreaseTotalStockUseCase decreaseTotalStockUseCase(BookRepository bookRepository, AuditMessagePort auditMessagePort) {
        return new DecreaseTotalStockService(bookRepository,auditMessagePort);
    }
    @Bean
    ReturnBookUseCase returnBookUseCase(BookRepository bookRepository, AuditMessagePort auditMessagePort) {
        return new ReturnBookService(bookRepository,auditMessagePort);
    }

    @Bean
    FindBookByAuthorUseCase findBookByAuthorUseCase(BookRepository bookRepository) {
        return new FindBookByAuthorService(bookRepository);
    }

    @Bean
    FindBookByGenreUseCase findBookByGenreUseCase(BookRepository bookRepository) {
        return new FindBookByGenreService(bookRepository);
    }

    @Bean
    FindBookByIdUseCase findBookByIdUseCase(BookRepository bookRepository) {
        return new FindBookByIdService(bookRepository);
    }

    @Bean
    FindBookByIsbnUseCase findBookByIsbnUseCase(BookRepository bookRepository) {
        return new FindBookByIsbnService(bookRepository);
    }

    @Bean
    FindBookByTitleUseCase findBookByTitleUseCase(BookRepository bookRepository) {
        return new FindBookByTitleService(bookRepository);
    }

    @Bean
    FindLowStockBookUseCase findLowStockBookUseCase(BookRepository bookRepository) {
        return new FindLowStockBookService(bookRepository);
    }

    @Bean
    GetAllBooksUseCase getAllBooksUseCase(BookRepository bookRepository) {
        return new GetAllBooksService(bookRepository);
    }

    @Bean
    PredictGenreUseCase predictGenreUseCase(AiGenrePredictorPort aiPort) {
        return new PredictGenreService(aiPort);
    }

    @Bean
    UpdateBookUseCase updateBookUseCase(BookRepository bookRepository, AuditMessagePort auditMessagePort) {
        return new UpdateBookService(bookRepository,auditMessagePort);
    }
    @Bean
    DeleteBookUseCase deleteBookUseCase(BookRepository bookRepository, AuditMessagePort auditMessagePort) {
        return new DeleteBookService(bookRepository,auditMessagePort);
    }
    @Bean
    public GetArchivedBooksUseCase getArchivedBooksUseCase(BookRepository bookRepository) {
        return new GetArchivedBooksService(bookRepository);
    }
    @Bean
    public MarkBookLostUseCase markBookLostUseCase(BookRepository repository, AuditMessagePort auditMessagePort) {
        return new MarkBookLostService(repository, auditMessagePort);
    }

    @Bean
    public RestoreLostBookUseCase restoreLostBookUseCase(BookRepository repository, AuditMessagePort auditMessagePort) {
        return new RestoreLostBookService(repository, auditMessagePort);
    }
    @Bean
    public RestoreBookUseCase restoreBookUseCase(BookRepository bookRepository, AuditMessagePort auditMessagePort) {
        return new RestoreBookService(bookRepository, auditMessagePort);
    }

}