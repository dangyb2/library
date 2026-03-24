package com.borrowservice.application.service;

import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.ExternalServiceUnavailableException;

import java.util.Set;

/**
 * Lớp dịch vụ mượn sách cơ bản (Trừu tượng)
 * Cung cấp các phương thức dùng chung để tương tác với kho sách và độc giả.
 */
abstract class BaseBorrowService {

    protected final BookCatalogPort bookCatalogPort;      // Cổng kết nối danh mục sách
    protected final ReaderRegistryPort readerRegistryPort; // Cổng kết nối đăng ký độc giả

    protected BaseBorrowService(BookCatalogPort bookCatalogPort, ReaderRegistryPort readerRegistryPort) {
        this.bookCatalogPort = bookCatalogPort;
        this.readerRegistryPort = readerRegistryPort;
    }

    // ---------------------------------------------

    protected void restoreBookStockSafely(String bookId) {
        try {
            bookCatalogPort.addBookStock(bookId);
        } catch (Exception e) {
            throw new ExternalServiceUnavailableException("Dịch vụ danh mục sách (Cập nhật kho hàng thất bại)");
        }
    }

    /**
     * Lấy tiêu đề sách dựa trên ID.
     * Trả về "Sách không xác định" nếu không tìm thấy.
     */
    protected String getBookTitle(String bookId) {
        return bookCatalogPort.getBookTitles(Set.of(bookId))
                .getOrDefault(bookId, "Sách không xác định");
    }

    /**
     * Lấy tên độc giả dựa trên ID.
     * Trả về "Độc giả không xác định" nếu không tìm thấy.
     */
    protected String getReaderName(String readerId) {
        return readerRegistryPort.getReaderNames(Set.of(readerId))
                .getOrDefault(readerId, "Độc giả không xác định");
    }
}