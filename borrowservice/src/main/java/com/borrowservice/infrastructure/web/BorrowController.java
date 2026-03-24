package com.borrowservice.infrastructure.web;

import com.borrowservice.infrastructure.dto.*;
import com.borrowservice.application.dto.*;
import com.borrowservice.application.port.in.*;
import com.borrowservice.application.port.in.command.*;
import com.borrowservice.domain.model.Status;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/borrows")
public class BorrowController {

    private final BorrowBookUseCase borrowBookUseCase;
    private final ReturnBookUseCase returnBookUseCase;
    private final ExtendBorrowTimeUseCase extendBorrowTimeUseCase;
    private final ReportBookLostUseCase reportBookLostUseCase;
    private final GetBorrowDetailsUseCase getBorrowDetailsUseCase;
    private final GetOverdueBorrowsUseCase getOverdueBorrowsUseCase;
    private final ListAllBorrowsUseCase listAllBorrowsUseCase;
    private final ListReaderBorrowsQuery listReaderBorrowsQuery;
    private final PaymentUseCase paymentUseCase;
    private final UpdateBorrowUseCase updateBorrowUseCase;
    private final CancelBorrowUseCase cancelBorrowUseCase;
    private final UndoCancelBorrowUseCase undoCancelBorrowUseCase;
    private final ReturnBookPreviewUseCase previewUseCase;
    private final FoundLostBookUseCase foundLostBookUseCase;
    public BorrowController(BorrowBookUseCase borrowBookUseCase, ReturnBookUseCase returnBookUseCase, ExtendBorrowTimeUseCase extendBorrowTimeUseCase, ReportBookLostUseCase reportBookLostUseCase, GetBorrowDetailsUseCase getBorrowDetailsUseCase, GetOverdueBorrowsUseCase getOverdueBorrowsUseCase, ListAllBorrowsUseCase listAllBorrowsUseCase, ListReaderBorrowsQuery listReaderBorrowsQuery, PaymentUseCase paymentUseCase, UpdateBorrowUseCase updateBorrowUseCase, CancelBorrowUseCase cancelBorrowUseCase, UndoCancelBorrowUseCase undoCancelBorrowUseCase, ReturnBookPreviewUseCase previewUseCase, FoundLostBookUseCase foundLostBookUseCase) {
        this.borrowBookUseCase = borrowBookUseCase;
        this.returnBookUseCase = returnBookUseCase;
        this.extendBorrowTimeUseCase = extendBorrowTimeUseCase;
        this.reportBookLostUseCase = reportBookLostUseCase;
        this.getBorrowDetailsUseCase = getBorrowDetailsUseCase;
        this.getOverdueBorrowsUseCase = getOverdueBorrowsUseCase;
        this.listAllBorrowsUseCase = listAllBorrowsUseCase;
        this.listReaderBorrowsQuery = listReaderBorrowsQuery;
        this.paymentUseCase = paymentUseCase;
        this.updateBorrowUseCase = updateBorrowUseCase;
        this.cancelBorrowUseCase = cancelBorrowUseCase;
        this.undoCancelBorrowUseCase = undoCancelBorrowUseCase;
        this.previewUseCase = previewUseCase;
        this.foundLostBookUseCase = foundLostBookUseCase;
    }
// --- Write Operations (Commands) ---

    @PostMapping
    public ResponseEntity<BorrowReceiptView> borrowBook(@RequestBody BorrowRequest request) {
        BorrowBookCommand command = new BorrowBookCommand(
                request.readerId(),
                request.bookId(),
                request.dueDate(),
                request.conditionBorrow()
        );
        BorrowReceiptView view = borrowBookUseCase.borrow(command);
        return ResponseEntity.status(HttpStatus.CREATED).body(view);
    }
    @PostMapping("/{borrowId}/return")
    public ResponseEntity<ReturnedBorrowView> returnBook(@PathVariable String borrowId,
                                                         @RequestBody ReturnRequest request) {
        ReturnBookCommand command = new ReturnBookCommand(
                borrowId,
                LocalDate.now(),
                request.conditionReturn()
        );
        ReturnedBorrowView view = returnBookUseCase.returnBook(command);
        return ResponseEntity.ok(view);
    }

    @PostMapping("/{borrowId}/extend")
    public ResponseEntity<ExtendBorrowResultView> extendBorrow(@PathVariable String borrowId,
                                                               @RequestBody ExtendRequest request) {
        ExtendBorrowCommand command = new ExtendBorrowCommand(
                borrowId,
                request.newDueDate()
        );
        ExtendBorrowResultView view = extendBorrowTimeUseCase.extend(command);
        return ResponseEntity.ok(view);
    }

    @PostMapping("/{borrowId}/lost")
    public ResponseEntity<LostReportResult> reportLost(@PathVariable String borrowId) {
        ReportLostCommand command = new ReportLostCommand(borrowId, LocalDate.now());

        LostReportResult result = reportBookLostUseCase.report(command);

        return ResponseEntity.ok(result);
    }
    @PostMapping("/{borrowId}/found")
    public ResponseEntity<Map<String, Object>> markBookFound(
            @PathVariable String borrowId,
            @RequestBody Map<String, String> requestBody) {

        // Safely extract the string and check for null
        String dateStr = requestBody.get("foundDate");
        LocalDate foundDate = (dateStr == null || dateStr.isBlank())
                ? LocalDate.now()
                : LocalDate.parse(dateStr);

        FoundLostBookCommand command = new FoundLostBookCommand(borrowId, foundDate);
        BigDecimal newFine = foundLostBookUseCase.markFound(command);

        return ResponseEntity.ok(Map.of(
                "message", "Book successfully marked as found and returned.",
                "updatedFine", newFine
        ));
    }
    // --- Read Operations (Queries) ---

    @GetMapping("/{borrowId}")
    public ResponseEntity<BorrowDetailsView> getBorrowDetails(@PathVariable String borrowId) {
        BorrowDetailsView view = getBorrowDetailsUseCase.get(borrowId);
        return ResponseEntity.ok(view);
    }

    @GetMapping("/overdue")
    public ResponseEntity<List<OverdueBorrowView>> getOverdueBorrows() {
        List<OverdueBorrowView> views = getOverdueBorrowsUseCase.list();
        return ResponseEntity.ok(views);
    }
    @GetMapping
    public ResponseEntity<List<BorrowSummaryView>> listAllBorrows() {
        List<BorrowSummaryView> views = listAllBorrowsUseCase.list();
        return ResponseEntity.ok(views);
    }
    @GetMapping("/reader/{readerId}")
    public ResponseEntity<List<BorrowSummaryView>> getReaderBorrows(
            @PathVariable String readerId,
            @RequestParam(required = false) Status status) {
        List<BorrowSummaryView> views = listReaderBorrowsQuery.list(readerId, status);
        return ResponseEntity.ok(views);
    }
    @PatchMapping("/{borrowId}/payment")
    public ResponseEntity<Void> payment(@PathVariable String borrowId) {
        paymentUseCase.pay(borrowId);
        return ResponseEntity.ok().build();
    }
    @PutMapping("/{borrowId}")
    public ResponseEntity<BorrowDetailsView> updateBorrow(
            @PathVariable String borrowId,
            @RequestBody UpdateBorrowRequest request) {

        UpdateBorrowCommand command = new UpdateBorrowCommand(
                borrowId,
                request.readerId(),
                request.bookId(),
                request.borrowDate(),
                request.dueDate(),
                request.conditionBorrow()
        );
        BorrowDetailsView view = updateBorrowUseCase.update(command);
        return ResponseEntity.ok(view);
    }
    @PatchMapping("/{borrowId}/cancel")
    public ResponseEntity<Void> cancelBorrow(@PathVariable("borrowId") String id) {
        cancelBorrowUseCase.cancelBorrow(id);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{borrowId}/undo-cancel")
    public ResponseEntity<Void> undoCancelBorrow(@PathVariable("borrowId") String id) {
        undoCancelBorrowUseCase.undoCancelBorrow(id);
        return ResponseEntity.ok().build();
    }
    @GetMapping("/{borrowId}/preview")
    public ReturnPreviewResult getReturnPreview(
            @PathVariable String borrowId,
            @RequestParam(required = false) LocalDate returnDate) {

        LocalDate dateToCalculate = (returnDate != null) ? returnDate : LocalDate.now();

        ReturnPreviewCommand command = new ReturnPreviewCommand(borrowId, dateToCalculate);

        return previewUseCase.preview(command);
    }
}

