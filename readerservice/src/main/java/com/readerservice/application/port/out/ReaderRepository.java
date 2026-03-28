package com.readerservice.application.port.out;

import com.readerservice.domain.model.Email;
import com.readerservice.domain.model.PhoneNumber;
import com.readerservice.domain.model.Reader;
import com.readerservice.domain.model.Status;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.Set;

public interface ReaderRepository {
    Reader save(Reader reader);

    Optional<Reader> findById(String id);

    List<Reader> findByIds(Set<String> ids);

    void deleteById(String id);

    List<Reader> findAll();

    Optional<Reader> findByEmail(Email email);


    Optional<Reader> findByPhone(PhoneNumber phone);

    List<Reader> findByName(String key);

    List<Reader> findByStatus(Status status);
    List<Reader> findByMembershipExpireAt(LocalDate date);

}
