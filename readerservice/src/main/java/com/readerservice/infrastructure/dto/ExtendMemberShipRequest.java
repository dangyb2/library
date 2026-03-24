package com.readerservice.infrastructure.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

/**
 * DTO đại diện cho request gia hạn thẻ thành viên
 */
public record ExtendMemberShipRequest(
        @NotNull(message = "New expiration date must not be null")
        LocalDate newExpireDate
) {
}
