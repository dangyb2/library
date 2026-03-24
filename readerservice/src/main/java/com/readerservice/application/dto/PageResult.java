package com.readerservice.application.dto;

import java.util.List;
import java.util.function.Function;

public record PageResult<T>(
        List<T> items,
        long totalElements,
        int totalPages,
        int page,
        int size
) {
    public <R> PageResult<R> map(Function<T, R> mapper) {
        return new PageResult<>(
                items.stream().map(mapper).toList(),
                totalElements,
                totalPages,
                page,
                size
        );
    }
}
