package com.readerservice.domain.exception;

/**
 * ReaderNotFoundException là exception thuộc tầng Application.
 *
 * Vai trò:
 * - Được ném ra khi use case không tìm thấy Reader theo id
 * - Biểu diễn một lỗi nghiệp vụ ở mức Application
 *   (không phải lỗi kỹ thuật như NullPointerException)
 *
 * Cách sử dụng:
 * - Được throw trong Application Service
 * - Sẽ được Web layer (Controller / ControllerAdvice)
 *   chuyển thành HTTP response phù hợp (ví dụ: 404 Not Found)
 *
 * Lưu ý thiết kế:
 * - Exception này KHÔNG thuộc Domain
 *   vì Domain không quan tâm đến khái niệm "không tìm thấy trong database"
 */
public class ReaderNotFoundException extends RuntimeException {

    /**
     * @param id định danh của Reader không tồn tại
     */
    public ReaderNotFoundException(long id) {
        super("Reader with id " + id + " not found");
    }

    public ReaderNotFoundException(String criteria) {
        super("Reader with " + criteria + " not found");
    }
}
