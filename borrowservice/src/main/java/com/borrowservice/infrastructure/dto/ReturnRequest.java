package com.borrowservice.infrastructure.dto;

import com.borrowservice.domain.model.BookCondition;

public record ReturnRequest(BookCondition conditionReturn) {}
