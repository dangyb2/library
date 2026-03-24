package com.readerservice.domain.model;

import java.util.regex.Pattern;

/**
 * Value object for reader phone number.
 */
public record PhoneNumber(String value) {
    private static final Pattern PHONE_PATTERN = Pattern.compile("^\\+?[0-9]{8,15}$");

    public PhoneNumber {
        if (value == null) {
            throw new IllegalArgumentException("Phone number must not be null");
        }

        String normalized = value.trim()
                .replace(" ", "")
                .replace("-", "")
                .replace(".", "");
        if (normalized.startsWith("00")) {
            normalized = "+" + normalized.substring(2);
        }

        if (normalized.isEmpty()) {
            throw new IllegalArgumentException("Phone number must not be blank");
        }
        if (!PHONE_PATTERN.matcher(normalized).matches()) {
            throw new IllegalArgumentException("Phone number format is invalid");
        }

        value = normalized;
    }

    @Override
    public String toString() {
        return value;
    }
}
