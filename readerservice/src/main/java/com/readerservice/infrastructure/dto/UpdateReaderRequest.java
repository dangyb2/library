package com.readerservice.infrastructure.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import java.time.LocalDate;

public record UpdateReaderRequest(
        @NotBlank(message = "Name must not be blank")
        String name,
        @NotBlank(message = "Email must not be blank")
        @Email(message = "Email format is invalid")
        String email,
        @NotBlank(message = "Phone must not be blank")
        @Pattern(
                regexp = "^\\+?[0-9 .-]{8,20}$",
                message = "Phone format is invalid"
        )
        String phone,
        @NotNull(message = "Membership expiration date must not be null")
        LocalDate membershipExpireAt
) {
}
