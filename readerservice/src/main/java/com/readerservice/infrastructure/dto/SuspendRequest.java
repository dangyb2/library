package com.readerservice.infrastructure.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * DTO đại diện cho request đình chỉ độc giả từ client
 */
public record SuspendRequest(
        @NotBlank(message = "Suspend reason must not be blank")
        String reason
) {
}
