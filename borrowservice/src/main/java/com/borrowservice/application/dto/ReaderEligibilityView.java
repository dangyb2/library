package com.borrowservice.application.dto;

import java.time.LocalDate;

public record ReaderEligibilityView(
        boolean eligible,
        LocalDate membershipExpireAt
) {}