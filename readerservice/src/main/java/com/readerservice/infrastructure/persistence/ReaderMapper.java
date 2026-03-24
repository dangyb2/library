package com.readerservice.infrastructure.persistence;

import com.readerservice.domain.model.Email;
import com.readerservice.domain.model.PhoneNumber;
import com.readerservice.domain.model.Reader;
import com.readerservice.domain.model.Status;

/**
 * ReaderMapper chịu trách nhiệm chuyển đổi dữ liệu giữa:
 * - ReaderEntity (Infrastructure / Persistence)
 * - Reader (Domain Entity)
 *
 * Mục đích:
 * - Giữ cho Domain không phụ thuộc JPA
 * - Tách biệt logic nghiệp vụ và chi tiết lưu trữ
 */
public class ReaderMapper {

    /**
     * Chuyển từ ReaderEntity (JPA Entity) sang Reader (Domain Entity)
     */
    public static Reader toDomain(ReaderEntity entity) {
        Reader reader = new Reader(
                entity.getId(),
                entity.getName(),
                new Email(entity.getEmail()),
                new PhoneNumber(entity.getPhone()),
                entity.getMembershipExpireAt()
        );
        if (entity.getStatus() == Status.SUSPENDED) {
            reader.suspend(entity.getSuspendReason());
        }

        return reader;
    }

    /**
     * Chuyển từ Reader (Domain Entity) sang ReaderEntity (JPA Entity)
     */
    public static ReaderEntity toPersistence(Reader reader) {
        ReaderEntity entity = new ReaderEntity();

        entity.setId(reader.getId());
        entity.setName(reader.getName());
        entity.setEmail(reader.getEmail().value());
        entity.setPhone(reader.getPhone().value());
        entity.setMembershipExpireAt(reader.getMembershipExpireAt());
        entity.setStatus(reader.getStatus());
        entity.setSuspendReason(reader.getSuspendReason());

        return entity;
    }
}
