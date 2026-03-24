package com.borrowservice.infrastructure.dto;

import com.borrowservice.domain.model.BookCondition;

import java.time.LocalDate;

public record BorrowRequest(String readerId, String bookId, LocalDate dueDate, BookCondition conditionBorrow) {}
