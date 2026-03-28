package com.readerservice.infrastructure.persistence;

import com.readerservice.domain.model.Email;
import com.readerservice.domain.model.PhoneNumber;
import com.readerservice.domain.model.Reader;


public class ReaderMapper {

    public static Reader toDomain(ReaderEntity entity) {
        // Use the new Reconstitution Constructor to set all fields directly!
        return new Reader(
                entity.getId(),
                entity.getName(),
                new Email(entity.getEmail()),
                new PhoneNumber(entity.getPhone()),
                entity.getMembershipExpireAt(),
                entity.getStatus(),
                entity.getSuspendReason()
        );
    }
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
