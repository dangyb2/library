package com.bookservice.application.port.out;

import com.bookservice.application.dto.BookTitleProjection;
import com.bookservice.domain.model.Book;
import java.util.List;
import java.util.Optional;
import java.util.Set;

public interface BookRepository {
    Book save(Book book);
    Optional<Book> findById(String id);
    List<Book> findAll();
    List<Book> findByTitleContainingIgnoreCase(String title);
    List<Book> findByAuthorIgnoreCase(String author);
    Optional<Book> findByIsbn(String isbn);
    List<Book> findByGenreIgnoreCase(String genre);
    List<Book> findLowStock(Long threshold);
    boolean existsByIsbn(String isbn);
    void deleteById(String id);
    List<BookTitleProjection> findByIdIn(Set<String> ids);
    List<Book> findAllDeletedBooks();
    int restoreBookById(String id);
    long countAll();
    long countLowStock(Long threshold);
}