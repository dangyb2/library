package com.bookservice.application.service;

import com.bookservice.application.dto.BookDetailView;
import com.bookservice.application.port.in.CreateBookUseCase;
import com.bookservice.application.port.in.command.CreateBookCommand;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.application.port.out.AuditMessagePort; // <-- 1. Nhập cổng thông báo mới của bạn
import com.bookservice.domain.exception.DuplicateIsbnException;
import com.bookservice.domain.model.Book;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;

/**
 * Dịch vụ xử lý việc thêm mới một đầu sách vào hệ thống.
 */
@Transactional
public class CreateBookService implements CreateBookUseCase {

    private final BookRepository bookRepository;      // Kho lưu trữ sách
    private final AuditMessagePort auditMessagePort; // Cổng gửi nhật ký hệ thống

    public CreateBookService(BookRepository bookRepository, AuditMessagePort auditMessagePort) {
        this.bookRepository = bookRepository;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public BookDetailView create(CreateBookCommand command) {
        // Làm sạch mã ISBN (loại bỏ dấu gạch ngang và khoảng trắng thừa)
        String cleanIsbn = command.isbn() != null ? command.isbn().replace("-", "").trim() : null;

        // Kiểm tra xem mã ISBN đã tồn tại trong hệ thống chưa
        if (command.isbn() != null && bookRepository.existsByIsbn(command.isbn())) {
            throw new DuplicateIsbnException(command.isbn());
        }

        // Xử lý danh sách thể loại (đảm bảo không bị null)
        Set<String> finalGenres = new HashSet<>();
        if (command.genres() != null) {
            finalGenres.addAll(command.genres());
        }

        // Khởi tạo thực thể Book (Domain Model)
        Book book = new Book(
                command.title(),
                command.author(),
                command.description(),
                cleanIsbn,
                command.shelfLocation(),
                command.publicationYear(),
                finalGenres,
                command.initialStock() != null ? command.initialStock() : 0L
        );

        // Lưu sách vào cơ sở dữ liệu
        Book savedBook = bookRepository.save(book);

        // Ghi nhật ký sự kiện hệ thống: Sách đã được tạo
        auditMessagePort.sendBookEvent(
                "BOOK_CREATED",
                savedBook.getId(),
                "Sách mới đã được tạo với tiêu đề: " + savedBook.getTitle()
        );

        // Trả về DTO hiển thị chi tiết sách vừa tạo
        return BookDetailView.fromBook(savedBook);
    }
}