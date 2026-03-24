package com.auditservice.infrastructure.web;

import com.auditservice.application.dto.AuditLogSummaryView;
import com.auditservice.application.port.in.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/audit-logs")
public class AuditLogController {

    private final GetAllAuditLogsUseCase getAllAuditLogs;
    private final GetAuditLogByIdUseCase getAuditLogById;
    private final GetAuditLogsByAggregateIdUseCase getByAggregate;
    private final GetAuditLogsByEventTypeUseCase getByEventType;
    private final GetAuditLogsByDateRangeUseCase getByDateRange;
    private final ReplayDeadLetterQueueUseCase replayDeadLetterQueueUseCase;

    public AuditLogController(GetAllAuditLogsUseCase getAllAuditLogs,
                              GetAuditLogByIdUseCase getAuditLogById,
                              GetAuditLogsByAggregateIdUseCase getByAggregate,
                              GetAuditLogsByEventTypeUseCase getByEventType,
                              GetAuditLogsByDateRangeUseCase getByDateRange, ReplayDeadLetterQueueUseCase replayDeadLetterQueueUseCase) {
        this.getAllAuditLogs = getAllAuditLogs;
        this.getAuditLogById = getAuditLogById;
        this.getByAggregate = getByAggregate;
        this.getByEventType = getByEventType;
        this.getByDateRange = getByDateRange;
        this.replayDeadLetterQueueUseCase = replayDeadLetterQueueUseCase;
    }

    @GetMapping
    public ResponseEntity<List<AuditLogSummaryView>> getAll() {
        return ResponseEntity.ok(getAllAuditLogs.get());
    }

    @GetMapping("/{id}")
    public ResponseEntity<AuditLogSummaryView> getById(@PathVariable String id) {
        return ResponseEntity.ok(getAuditLogById.get(id));
    }

    @GetMapping("/aggregate/{aggregateId}")
    public ResponseEntity<List<AuditLogSummaryView>> getByAggregate(
            @PathVariable String aggregateId) {
        return ResponseEntity.ok(getByAggregate.get(aggregateId));
    }

    @GetMapping("/event-type/{eventType}")
    public ResponseEntity<List<AuditLogSummaryView>> getByEventType(
            @PathVariable String eventType) {
        return ResponseEntity.ok(getByEventType.get(eventType));
    }

    @GetMapping("/date-range")
    public ResponseEntity<List<AuditLogSummaryView>> getByDateRange(
            @RequestParam String from,
            @RequestParam String to) {
        return ResponseEntity.ok(getByDateRange.get(from, to));
    }
    @PostMapping("/dlt/replay")
    public ResponseEntity<String> replayDlt() {
        int replayedCount = replayDeadLetterQueueUseCase.replay();
        return ResponseEntity.ok("Successfully replayed " + replayedCount + " messages from the DLT back into the main topic.");
    }
}