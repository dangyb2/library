package com.bookservice.infrastructure.persistence;

import com.bookservice.application.dto.BookTitleProjection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.Set;

public interface SpringDataBookRepository extends JpaRepository<BookEntity, String> {

    List<BookEntity> findByTitleContainingIgnoreCase(String title);

    List<BookEntity> findByAuthorIgnoreCase(String author);

    Optional<BookEntity> findByIsbn(String isbn);

    List<BookEntity> findByAvailableStockLessThan(Long threshold);
    boolean existsByIsbn(String isbn);
    @Query("""
    SELECT DISTINCT b
    FROM BookEntity b
    JOIN b.genres g
    WHERE LOWER(g) LIKE LOWER(CONCAT('%', :genre, '%'))
""")
    List<BookEntity> findByGenreContainingIgnoreCase(@Param("genre") String genre);
    @Query(value = "SELECT id, title FROM books WHERE id IN (:ids)", nativeQuery = true)
    List<BookTitleProjection> findTitlesByIdIn(Set<String> ids);

    // --- RECYCLE BIN ---

    @Query(value = "SELECT * FROM books WHERE is_deleted = 1", nativeQuery = true)
    List<BookEntity> findAllDeletedBooks();

    @Modifying
    @Query(value = "UPDATE books SET is_deleted = 0 WHERE id = :id", nativeQuery = true)
    int restoreBookById(@Param("id") String id);
}