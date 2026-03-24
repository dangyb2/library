package com.auditservice.application.util;

import com.auditservice.domain.exception.InvalidAuditLogException;

import java.time.Instant;
import java.time.format.DateTimeParseException;

public final class InstantParser {

    private InstantParser() {}

    public static Instant parse(String value, String field) {
        if (value == null || value.isBlank())
            throw new InvalidAuditLogException(field, "must not be null or blank");
        try {
            return Instant.parse(value);
        } catch (DateTimeParseException e) {
            throw new InvalidAuditLogException(field,
                    "invalid format, expected ISO-8601 but got: '" + value + "'");
        }
    }
}