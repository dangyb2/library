package com.bookservice.domain.model;

public record Isbn(String value) {

    public Isbn {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("ISBN must not be blank.");
        }

        value = value.replaceAll("[\\s-]", "");

        if (!value.matches("^(\\d{10}|\\d{13})$")) {
            throw new IllegalArgumentException("ISBN must be 10 or 13 digits.");
        }
    }

    @Override
    public String toString() {
        return value;
    }
}