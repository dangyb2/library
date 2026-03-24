package com.readerservice.infrastructure.persistence;

import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.Email;
import com.readerservice.domain.model.PhoneNumber;
import com.readerservice.domain.model.Reader;

import java.util.List;
import java.util.Optional;

/**
 * JpaReaderRepository là Persistence Adapter.
 *
 * Vai trò:
 * - Triển khai ReaderRepository (Application Port)
 * - Sử dụng Spring Data JPA để truy cập database
 * - Chuyển đổi dữ liệu giữa Domain Entity và JPA Entity thông qua Mapper
 *
 * Lớp này giúp:
 * - Application layer không phụ thuộc Spring / JPA
 * - Domain giữ được sự thuần khiết (clean)
 */
public class JpaReaderRepository implements ReaderRepository {
    private final SpringDataReaderRepository jpaRepos;

    public JpaReaderRepository(SpringDataReaderRepository jpaRepos) {
        this.jpaRepos = jpaRepos;
    }

    @Override
    public Reader save(Reader reader) {
        ReaderEntity entity = ReaderMapper.toPersistence(reader);
        ReaderEntity saved = jpaRepos.save(entity);
        return ReaderMapper.toDomain(saved);
    }

    /**
     * Tìm Reader theo id
     */
    @Override
    public Optional<Reader> findById(String id) {
        return jpaRepos.findById(id)
                .map(ReaderMapper::toDomain);
    }

    /**
     * Lấy toàn bộ Reader
     */
    @Override
    public List<Reader> findAll() {
        return jpaRepos.findAll().stream()
                .map(ReaderMapper::toDomain)
                .toList();
    }

    /**
     * Tìm Reader theo email
     */
    @Override
    public Optional<Reader> findByEmail(Email email) {
        return jpaRepos.findByEmail(email.value())
                .map(ReaderMapper::toDomain);
    }

    /**
     * Tìm Reader theo số điện thoại
     */
    @Override
    public Optional<Reader> findByPhone(PhoneNumber phone) {
        return jpaRepos.findByPhone(phone.value())
                .map(ReaderMapper::toDomain);
    }

    /**
     * Tìm danh sách Reader theo tên (không phân biệt hoa thường)
     */
    @Override
    public List<Reader> findByName(String key) {
        return jpaRepos.findByNameContainingIgnoreCase(key).stream()
                .map(ReaderMapper::toDomain)
                .toList();
    }


}
