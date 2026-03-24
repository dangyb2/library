package com.readerservice.application.port.out;

import com.readerservice.domain.model.Email;
import com.readerservice.domain.model.PhoneNumber;
import com.readerservice.domain.model.Reader;

import java.util.List;
import java.util.Optional;

/**
 * ReaderRepository là cổng ra (Output Port) của tầng Application.
 *
 * - Định nghĩa các thao tác cần thiết để truy xuất và lưu trữ Reader
 * - KHÔNG phụ thuộc vào database hay framework (JPA, JDBC, ...)
 * - Các lớp implement sẽ nằm ở tầng Infrastructure (Adapter)
 *
 * Application layer chỉ làm việc với interface này,
 * không biết chi tiết Reader được lưu trữ như thế nào.
 */
public interface ReaderRepository {

    /**
     * Lưu một Reader vào hệ thống.
     * Có thể dùng cho cả tạo mới hoặc cập nhật.
     */
    Reader save(Reader reader);

    Optional<Reader> findById(String id);

    List<Reader> findAll();

    Optional<Reader> findByEmail(Email email);


    Optional<Reader> findByPhone(PhoneNumber phone);

    /**
     * Tìm danh sách Reader theo tên (tìm kiếm gần đúng)
     */
    List<Reader> findByName(String key);


}
