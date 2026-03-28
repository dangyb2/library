package com.readerservice.domain.model;

import com.readerservice.domain.exception.ReaderValidationException;

import java.util.regex.Pattern;

/**
 * Value object for reader email.
 */
public record Email(String value) {
    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    public Email {
        if (value == null) {
            throw new ReaderValidationException("Email không được để trống");
        }

        String normalized = value.trim().toLowerCase();
        if (normalized.isEmpty()) {
            throw new ReaderValidationException("Email không được để trống");
        }
        if (!EMAIL_PATTERN.matcher(normalized).matches()) {
            throw new ReaderValidationException("Định dạng email không hợp lệ");
        }

        value = normalized;
    }

    @Override
    public String toString() {
        return value;
    }
}
