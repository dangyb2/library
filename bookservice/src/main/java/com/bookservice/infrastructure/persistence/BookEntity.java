package com.bookservice.infrastructure.persistence;

import jakarta.persistence.*;
import org.hibernate.annotations.Fetch;
import org.hibernate.annotations.FetchMode;
import org.hibernate.annotations.Nationalized; // Thêm import này
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

@Entity
@SQLDelete(sql = "UPDATE books SET is_deleted = 1 WHERE id=? AND version=?")
@SQLRestriction("is_deleted = 0")
@Table(name = "books")
public class BookEntity {
    @Id
    @Column(name = "id", length = 50, nullable = false, updatable = false)
    private String id;

    // THÊM @Nationalized cho các cột chứa tiếng Việt
    @Nationalized
    @Column(name = "title", nullable = false)
    private String title;

    @Nationalized
    @Column(name = "author", nullable = false)
    private String author;

    // Thay TEXT bằng NVARCHAR(MAX) vì TEXT trong SQL Server không lưu được Unicode chuẩn
    @Nationalized
    @Column(name = "description", columnDefinition = "NVARCHAR(MAX)", nullable = false)
    private String description;

    @Column(name = "isbn", length = 13, unique = true)
    private String isbn;

    // Tên kệ sách cũng có thể chứa tiếng Việt (ví dụ: "Kệ Tầng 1 - Khoa Học")
    @Nationalized
    @Column(name = "shelf_location")
    private String shelfLocation;

    @Column(name = "publication_year")
    private Integer publicationYear;

    @Column(name = "added_date", nullable = false, updatable = false)
    private LocalDate addedDate;

    // --- INVENTORY COLUMNS ---
    @Column(name = "total_stock", nullable = false)
    private Long totalStock;

    @Column(name = "available_stock", nullable = false)
    private Long availableStock;

    @Version
    @Column(name = "version")
    private Long version;

    @Column(name = "is_deleted", nullable = false)
    private boolean isDeleted = false;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "book_genres", joinColumns = @JoinColumn(name = "book_id"))
    @Nationalized // Cột genre trong bảng phụ book_genres cũng cần lưu tiếng Việt (VD: "Tiểu thuyết")
    @Column(name = "genre")
    @Fetch(FetchMode.SUBSELECT)
    private Set<String> genres = new HashSet<>();

    protected BookEntity() {}

    // 2. All-args constructor for mapping from Domain
    public BookEntity(String id, String title, String author, String description,
                      String isbn, String shelfLocation, Integer publicationYear,
                      LocalDate addedDate, Long totalStock, Long availableStock, Set<String> genres) {
        this.id = id;
        this.title = title;
        this.author = author;
        this.description = description;
        this.isbn = isbn;
        this.shelfLocation = shelfLocation;
        this.publicationYear = publicationYear;
        this.addedDate = addedDate;
        this.totalStock = totalStock;
        this.availableStock = availableStock;
        this.genres = genres;
        this.isDeleted = false; // Always false when creating/mapping a normal active book
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getAuthor() { return author; }
    public void setAuthor(String author) { this.author = author; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getIsbn() { return isbn; }
    public void setIsbn(String isbn) { this.isbn = isbn; }

    public String getShelfLocation() { return shelfLocation; }
    public void setShelfLocation(String shelfLocation) { this.shelfLocation = shelfLocation; }

    public Integer getPublicationYear() { return publicationYear; }
    public void setPublicationYear(Integer publicationYear) { this.publicationYear = publicationYear; }

    public LocalDate getAddedDate() { return addedDate; }
    public void setAddedDate(LocalDate addedDate) { this.addedDate = addedDate; }

    public Long getTotalStock() { return totalStock; }
    public void setTotalStock(Long totalStock) { this.totalStock = totalStock; }

    public Long getAvailableStock() { return availableStock; }
    public void setAvailableStock(Long availableStock) { this.availableStock = availableStock; }

    public Set<String> getGenres() { return genres; }
    public void setGenres(Set<String> genres) { this.genres = genres; }

    public Long getVersion() { return version; }
    public void setVersion(Long version) { this.version = version; }
    public boolean isDeleted() { return isDeleted; }
    public void setDeleted(boolean deleted) { isDeleted = deleted; }
}