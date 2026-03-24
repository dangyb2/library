package com.bookservice.application.port.in.command;

import java.util.Set;

public record CreateBookCommand(
        String title,
        String author,
        String description,
        String isbn,
        String shelfLocation,
        Integer publicationYear,
        Set<String> genres,
        Long initialStock
) {}