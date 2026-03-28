package com.readerservice.domain.model;

import com.readerservice.domain.exception.ReaderValidationException;

import java.util.regex.Pattern;

/**
 * Value object for reader phone number.
 */
public record PhoneNumber(String value) {
    private static final Pattern PHONE_PATTERN = Pattern.compile("^\\+?[0-9]{8,15}$");

    public PhoneNumber {
        if (value == null) {
            throw new ReaderValidationException("Số điện thoại không được để trống");
        }

        String normalized = value.trim()
                .replace(" ", "")
                .replace("-", "")
                .replace(".", "");
        if (normalized.startsWith("00")) {
            normalized = "+" + normalized.substring(2);
        }

        if (normalized.isEmpty()) {
            throw new ReaderValidationException("Số điện thoại không được để trống");
        }
        if (!PHONE_PATTERN.matcher(normalized).matches()) {
            throw new ReaderValidationException("Định dạng số điện thoại không hợp lệ");
        }

        value = normalized;
    }

    @Override
    public String toString() {
        return value;
    }
}
