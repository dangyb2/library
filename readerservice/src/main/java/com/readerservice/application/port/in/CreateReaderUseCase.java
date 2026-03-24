package com.readerservice.application.port.in;

import java.time.LocalDate;

public interface CreateReaderUseCase {

    String create(String name, String email, String phone, LocalDate expireAt);
}
