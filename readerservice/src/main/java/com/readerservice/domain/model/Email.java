package com.readerservice.domain.model;

import java.util.regex.Pattern;

/**
 * Value object for reader email.
 */
public record Email(String value) {
    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    public Email {
        if (value == null) {
            throw new IllegalArgumentException("Email must not be null");
        }

        String normalized = value.trim().toLowerCase();
        if (normalized.isEmpty()) {
            throw new IllegalArgumentException("Email must not be blank");
        }
        if (!EMAIL_PATTERN.matcher(normalized).matches()) {
            throw new IllegalArgumentException("Email format is invalid");
        }

        value = normalized;
    }

    @Override
    public String toString() {
        return value;
    }
}
