package com.readerservice.application.service;

import com.readerservice.domain.exception.ReaderAlreadyExistsException;
import com.readerservice.application.port.in.CreateReaderUseCase;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.Email;
import com.readerservice.domain.model.PhoneNumber;
import com.readerservice.domain.model.Reader;

import java.time.LocalDate;
import java.util.UUID; // Import UUID!

public class CreateReaderService implements CreateReaderUseCase {
    private final ReaderRepository readerRepository;

    public CreateReaderService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    // 1. Change the return type from 'long' to 'String'
    @Override
    public String create(String name, String email, String phone, LocalDate expireAt) {
        Email emailValue = new Email(email);
        PhoneNumber phoneValue = new PhoneNumber(phone);

        if (readerRepository.findByEmail(emailValue).isPresent()) {
            throw ReaderAlreadyExistsException.forEmail(emailValue.value());
        }
        if (readerRepository.findByPhone(phoneValue).isPresent()) {
            throw ReaderAlreadyExistsException.forPhone(phoneValue.value());
        }

        // 2. Generate the unique ID right here in the application service
        String newReaderId = "READER-"+UUID.randomUUID().toString();

        Reader reader = new Reader(
                newReaderId, // 3. Pass the generated ID instead of null
                name,
                emailValue,
                phoneValue,
                expireAt
        );

        // 4. Return the String ID
        return readerRepository.save(reader).getId();
    }
}