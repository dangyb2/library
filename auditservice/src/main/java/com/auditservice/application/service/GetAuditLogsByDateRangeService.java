package com.auditservice.application.service;

import com.auditservice.application.dto.AuditLogSummaryView;
import com.auditservice.application.port.in.GetAuditLogsByDateRangeUseCase;
import com.auditservice.application.port.out.AuditLogRepository;
import com.auditservice.application.util.InstantParser;
import com.auditservice.domain.exception.InvalidAuditLogException;

import java.time.Instant;
import java.util.List;

public class GetAuditLogsByDateRangeService implements GetAuditLogsByDateRangeUseCase {
    private final AuditLogRepository repository;

    public GetAuditLogsByDateRangeService(AuditLogRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<AuditLogSummaryView> get(String from, String to) {
        Instant fromInstant = InstantParser.parse(from, "from");
        Instant toInstant   = InstantParser.parse(to,   "to");

        if (fromInstant.isAfter(toInstant))
            throw new InvalidAuditLogException("from", "must not be after 'to'");

        return repository.findByDateRange(fromInstant, toInstant)
                .stream()
                .map(AuditLogSummaryView::from)
                .toList();
    }
}
