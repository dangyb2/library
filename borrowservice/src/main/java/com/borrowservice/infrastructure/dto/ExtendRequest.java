package com.borrowservice.infrastructure.dto;

import java.time.LocalDate;

public record ExtendRequest(LocalDate newDueDate) {}