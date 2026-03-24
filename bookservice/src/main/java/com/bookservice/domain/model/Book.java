package com.bookservice.domain.model;

import com.bookservice.domain.exception.InsufficientStockException;
import com.bookservice.domain.exception.InvalidBookDataException;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

public class Book {

    private String id;
    private String title;
    private String author;
    private String description;
    private Isbn isbn;
    private String shelfLocation;
    private Integer publicationYear;
    private LocalDate addedDate;
    private Set<String> genres = new HashSet<>();

    // Split into Total and Available
    private Long totalStock;
    private Long availableStock;

    // 1. For Hibernate/JPA
    protected Book() {}

    // 2. For Creating a BRAND NEW Book (Generates ID and Date)
    public Book(String title, String author, String description, String isbn,
                String shelfLocation, Integer publicationYear,
                Set<String> genres, Long initialStock) {

        this.id = "BOOK-" + UUID.randomUUID();
        this.addedDate = LocalDate.now();

        // When buying a brand new book, available stock perfectly equals total stock
        init(title, author, description, isbn, shelfLocation, publicationYear, genres, initialStock, initialStock);
    }
    public Book(String id, LocalDate addedDate, String title, String author,
                String description, String isbn, String shelfLocation,
                Integer publicationYear, Set<String> genres, Long totalStock, Long availableStock) {

        // Kiểm tra các trường bắt buộc ngay tại Constructor
        if (id == null || id.isBlank()) throw new InvalidBookDataException("ID không được để trống");
        if (addedDate == null) throw new InvalidBookDataException("Ngày thêm sách không được để trống");

        this.id = id;
        this.addedDate = addedDate;

        // Gọi hàm khởi tạo chi tiết
        init(title, author, description, isbn, shelfLocation, publicationYear, genres, totalStock, availableStock);
    }

    private void init(String title, String author, String description, String isbn,
                      String shelfLocation, Integer publicationYear,
                      Set<String> genres, Long totalStock, Long availableStock) {

        // 1. Kiểm tra logic kho hàng
        if (totalStock == null || totalStock < 0) {
            throw new InvalidBookDataException("Tổng số lượng trong kho phải từ 0 trở lên");
        }

        // Quy tắc quan trọng: Sách sẵn có không thể âm và không được vượt quá tổng số lượng sở hữu
        if (availableStock == null || availableStock < 0 || availableStock > totalStock) {
            throw new InvalidBookDataException("Số lượng sẵn có không được nhỏ hơn 0 hoặc lớn hơn tổng kho");
        }

        // 2. Gán các giá trị thông qua các phương thức Setter (để tận dụng validation riêng của từng trường)
        setTitle(title);
        setAuthor(author);
        setDescription(description);
        setIsbn(isbn);
        setShelfLocation(shelfLocation);
        setPublicationYear(publicationYear);
        setGenres(genres);

        this.totalStock = totalStock;
        this.availableStock = availableStock;
    }

    public void updateDetails(String title, String author, String description, String isbn,
                              String shelfLocation, Integer publicationYear, Set<String> genres) {
        setTitle(title);
        setAuthor(author);
        setDescription(description);
        setIsbn(isbn);
        setShelfLocation(shelfLocation);
        setPublicationYear(publicationYear);
        setGenres(genres);
    }

    // --- HELPER METHODS ---

    public static String capitalize(String name) {
        if (name == null || name.isEmpty()) {
            return name;
        }

        String[] words = name.toLowerCase().split("\\s+");
        StringBuilder result = new StringBuilder();

        for (String word : words) {
            if (!word.isEmpty()) {
                result.append(Character.toUpperCase(word.charAt(0)))
                        .append(word.substring(1))
                        .append(" ");
            }
        }

        return result.toString().trim();
    }
    /**
     * Loại bỏ khoảng trắng thừa ở hai đầu chuỗi.
     */
    private String removeBlank(String giaTri) {
        return giaTri == null ? null : giaTri.trim();
    }

    /**
     * Kiểm tra xem trường dữ liệu có bị rỗng hoặc null hay không.
     * Nếu rỗng, ném ra ngoại lệ InvalidBookDataException với tên trường tương ứng.
     */
    private void checkBlank(String giaTri, String tenTruong) {
        if (giaTri == null || giaTri.isBlank()) {
            throw new InvalidBookDataException(tenTruong + " không được để trống.");
        }
    }

// --- CÁC HÀM GETTER & SETTER ---

    public String getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        checkBlank(title, "Tiêu đề");
        this.title = removeBlank(title);
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        checkBlank(author, "Tác giả");
        // Chuẩn hóa: Loại bỏ khoảng trắng và viết hoa tên tác giả (nếu có hàm capitalize)
        this.author = capitalize(removeBlank(author));
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        checkBlank(description, "Mô tả");
        this.description = removeBlank(description);
    }

    public String getShelfLocation() {
        return shelfLocation;
    }
    public void setShelfLocation(String shelfLocation) { this.shelfLocation = removeBlank(shelfLocation); }
    public String getIsbn() { return isbn == null ? null : isbn.value(); }
    public void setIsbn(String isbnString) {
        String clean = removeBlank(isbnString);
        this.isbn = clean == null ? null : new Isbn(clean);
    }
    public Integer getPublicationYear() { return publicationYear; }
    public void setPublicationYear(Integer publicationYear) { this.publicationYear = publicationYear; }
    public LocalDate getAddedDate() { return addedDate; }
    public Set<String> getGenres() { return new HashSet<>(this.genres); }
    public void setGenres(Set<String> genres) {
        if (genres == null) return;
        this.genres = new HashSet<>(genres);
    }
    public void addGenres(Set<String> genres) {
        if (genres == null) return;
        this.genres.addAll(genres);
    }
    public void removeGenres(Set<String> genres) {
        if (genres == null) return;
        this.genres.removeAll(genres);
    }

    // --- INVENTORY MANAGEMENT ---

    public Long getTotalStock() {
        return totalStock;
    }

    public Long getAvailableStock() {
        return availableStock;
    }

    public Long getLentOutCount() {
        return totalStock - availableStock;
    }

    // Use this when the library buys more copies of an existing book
    public void addInventory(long amount) {
        // Kiểm tra số lượng nhập vào
        if (amount <= 0) throw new InvalidBookDataException("Số lượng thêm vào phải là số dương");

        this.totalStock += amount;
        this.availableStock += amount;
    }

    /**
     * Sử dụng khi độc giả trả sách.
     * Chỉ tăng số lượng 'sẵn có', không thay đổi tổng kho.
     */
    public void increaseAvailableStock(long amount) {
        if (amount <= 0) throw new InvalidBookDataException("Số lượng phải là số dương");

        // Đảm bảo dữ liệu logic: Sách trả về không được làm số lượng sẵn có vượt quá tổng số lượng sở hữu
        if (this.availableStock + amount > this.totalStock)
            throw new InvalidBookDataException("Số lượng sẵn có không thể vượt quá tổng kho");

        this.availableStock += amount;
    }

    public void markCopyAsLostByReader() {
        // Tính toán số lượng sách đang được mượn (nằm ngoài kho)
        long currentlyLentOut = this.totalStock - this.availableStock;

        if (currentlyLentOut <= 0) {
            throw new InvalidBookDataException(
                    "Không thể đánh dấu sách bị mất bởi độc giả. Hiện không có bản sao nào đang được mượn."
            );
        }

        // Khi mất sách, tổng kho thực tế sẽ giảm đi 1
        this.totalStock -= 1;
    }

    public void restoreLostCopy() {
        // Khi tìm thấy sách từng báo mất, tăng cả tổng kho và số lượng sẵn có
        this.totalStock += 1;
        this.availableStock += 1;
    }

    /**
     * Sử dụng khi độc giả mượn sách.
     */
    public void decreaseAvailableStock(long amount) {
        if (amount <= 0) throw new InvalidBookDataException("Số lượng phải là số dương");

        // Kiểm tra xem còn đủ sách trong kho để cho mượn không
        if (this.availableStock - amount < 0)
            throw new InsufficientStockException(this.id, this.availableStock, amount);

        this.availableStock -= amount;
    }

    public void removeCopies(long amount) {
        if (amount <= 0) throw new InvalidBookDataException("Số lượng phải là số dương");

        // Kiểm tra nếu số lượng cần xóa lớn hơn tổng kho hiện có
        if (amount > this.totalStock)
            throw new InsufficientStockException(this.id, this.totalStock, amount);

        // Quy tắc quan trọng: Không được xóa các bản sao đang được người khác mượn
        if (amount > this.availableStock)
            throw new InvalidBookDataException("Không thể xóa " + amount + " bản sao — hiện có "
                    + (this.totalStock - this.availableStock) + " cuốn đang được mượn chưa trả.");

        this.totalStock -= amount;
        this.availableStock -= amount;
    }
    public Book copy() {
        return new Book(
                this.id,
                this.addedDate,
                this.title,
                this.author,
                this.description,
                this.getIsbn(),
                this.shelfLocation,
                this.publicationYear,
                this.genres,
                this.totalStock,
                this.availableStock
        );
    }
}