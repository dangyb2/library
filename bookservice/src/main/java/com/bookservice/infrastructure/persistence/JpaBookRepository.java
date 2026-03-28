package com.bookservice.infrastructure.persistence;

import com.bookservice.application.dto.BookTitleProjection;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.model.Book;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

public class JpaBookRepository implements BookRepository {

    private final SpringDataBookRepository springDataRepository;

    public JpaBookRepository(SpringDataBookRepository springDataRepository) {
        this.springDataRepository = springDataRepository;
    }

    @Override
    public List<BookTitleProjection> findByIdIn(Set<String> ids) {
        return springDataRepository.findTitlesByIdIn(ids);
    }


    @Override
    public boolean existsByIsbn(String isbn) {
        return springDataRepository.existsByIsbn(isbn);
    }
    @Override
    public long countAll() {
        return springDataRepository.count();
    }
    @Override
    public long countLowStock(Long threshold) { // <-- Changed to Long
        return springDataRepository.countByTotalStockLessThanEqual(threshold);
    }
    @Override
    public Book save(Book book) {
        BookEntity entity = springDataRepository.findById(book.getId())
                .orElseGet(() -> BookMapper.toEntity(book));

        entity.setTitle(book.getTitle());
        entity.setAuthor(book.getAuthor());
        entity.setDescription(book.getDescription());
        entity.setIsbn(book.getIsbn());
        entity.setShelfLocation(book.getShelfLocation());
        entity.setPublicationYear(book.getPublicationYear());
        entity.setGenres(book.getGenres());

        entity.setTotalStock(book.getTotalStock());
        entity.setAvailableStock(book.getAvailableStock());

        BookEntity saved = springDataRepository.save(entity);

        return BookMapper.toDomain(saved);
    }
    @Override
    public List<Book> findAllDeletedBooks() {
        // 1. Fetch the soft-deleted entities using the native query
        List<BookEntity> deletedEntities = springDataRepository.findAllDeletedBooks();

        // 2. Map them back to Domain objects
        return deletedEntities.stream()
                .map(BookMapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public int restoreBookById(String id) {
        // Pass the call straight through to the native Spring Data query
        return springDataRepository.restoreBookById(id);
    }
    @Override
    public Optional<Book> findById(String id) {
        return springDataRepository.findById(id).map(BookMapper::toDomain);
    }

    @Override
    public List<Book> findAll() {
        return springDataRepository.findAll()
                .stream()
                .map(BookMapper::toDomain)
                .toList();
    }

    @Override
    public List<Book> findByTitleContainingIgnoreCase(String title) {
        return springDataRepository.findByTitleContainingIgnoreCase(title)
                .stream()
                .map(BookMapper::toDomain)
                .toList();
    }

    @Override
    public List<Book> findByAuthorIgnoreCase(String author) {
        return springDataRepository.findByAuthorIgnoreCase(author)
                .stream()
                .map(BookMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<Book> findByIsbn(String isbn) {
        return springDataRepository.findByIsbn(isbn).map(BookMapper::toDomain);
    }

    @Override
    public List<Book> findByGenreIgnoreCase(String genre) {
        return springDataRepository.findByGenreContainingIgnoreCase(genre)
                .stream()
                .map(BookMapper::toDomain)
                .toList();
    }

    @Override
    public List<Book> findLowStock(Long threshold) {
        // --- WE ALSO UPDATE THIS TO CHECK AVAILABLE STOCK ---
        return springDataRepository.findByAvailableStockLessThan(threshold)
                .stream()
                .map(BookMapper::toDomain)
                .toList();
    }
    @Override
    public void deleteById(String id) {
        springDataRepository.deleteById(id);
    }
}