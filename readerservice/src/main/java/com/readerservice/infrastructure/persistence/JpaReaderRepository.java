package com.readerservice.infrastructure.persistence;

import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.Email;
import com.readerservice.domain.model.PhoneNumber;
import com.readerservice.domain.model.Reader;
import com.readerservice.domain.model.Status;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.Set;


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


    @Override
    public Optional<Reader> findById(String id) {
        return jpaRepos.findById(id)
                .map(ReaderMapper::toDomain);
    }

    @Override
    public List<Reader> findByIds(Set<String> ids) {
        return jpaRepos.findAllById(ids).stream()
                .map(ReaderMapper::toDomain)
                .toList();
    }

    @Override
    public void deleteById(String id) {
        jpaRepos.deleteById(id);
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

    @Override
    public List<Reader> findByStatus(Status status) {
        return jpaRepos.findByStatus(status).stream()
                .map(ReaderMapper::toDomain)
                .toList();
    }
    @Override
    public List<Reader> findByMembershipExpireAt(LocalDate date) {
        return jpaRepos.findByMembershipExpireAt(date)
                .stream()
                .map(ReaderMapper::toDomain)
                .toList();
    }

}
