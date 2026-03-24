package com.readerservice.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * SpringDataReaderRepository là interface do Spring Data JPA cung cấp.
 *
 * - Spring sẽ tự động tạo class implement interface này khi ứng dụng chạy
 * - Không cần tự viết code truy vấn SQL hay EntityManager
 *
 * Vai trò trong kiến trúc:
 * - Thuộc tầng Infrastructure
 * - Chỉ dùng để làm việc với database
 * - KHÔNG được gọi trực tiếp từ Application / Domain
 *
 * Repository này sẽ được sử dụng bên trong một Adapter
 * để triển khai ReaderRepository (Application Port).
 */
public interface SpringDataReaderRepository
        extends JpaRepository<ReaderEntity, String> {


    Optional<ReaderEntity> findByEmail(String email);

    Optional<ReaderEntity> findByPhone(String phone);

    List<ReaderEntity> findByNameContainingIgnoreCase(String key);

    Page<ReaderEntity> findByNameContainingIgnoreCase(String key, Pageable pageable);
}
