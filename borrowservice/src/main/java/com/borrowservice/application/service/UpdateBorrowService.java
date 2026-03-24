package com.borrowservice.application.service;

import com.borrowservice.application.dto.BorrowDetailsView;
import com.borrowservice.application.port.in.UpdateBorrowUseCase;
import com.borrowservice.application.port.in.command.UpdateBorrowCommand;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.model.Borrow;
import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

/**
 * Dịch vụ xử lý việc cập nhật hoặc hiệu chỉnh thông tin bản ghi mượn sách.
 */
@Transactional
public class UpdateBorrowService implements UpdateBorrowUseCase {

    private final BookBorrowRepository repository;
    private final AuditMessagePort auditMessagePort;
    private final BookCatalogPort bookCatalogPort;       // Đã thêm
    private final ReaderRegistryPort readerRegistryPort; // Đã thêm

    public UpdateBorrowService(
            BookBorrowRepository repository,
            AuditMessagePort auditMessagePort,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        this.repository = repository;
        this.auditMessagePort = auditMessagePort;
        this.bookCatalogPort = bookCatalogPort;
        this.readerRegistryPort = readerRegistryPort;
    }

    @Override
    public BorrowDetailsView update(UpdateBorrowCommand command) {
        // 1. Tìm bản ghi mượn sách, ném lỗi nếu không tồn tại ID
        Borrow borrow = repository.findById(command.borrowId())
                .orElseThrow(() -> BorrowRecordNotFoundException.byRecordId(command.borrowId()));

        // 2. Thực thi logic hiệu chỉnh dữ liệu trong tầng Domain
        borrow.correctBorrowData(
                command.readerId(),
                command.bookId(),
                command.borrowDate(),
                command.dueDate(),
                command.conditionBorrow()
        );

        // 3. Lưu bản ghi đã cập nhật vào cơ sở dữ liệu
        Borrow saved = repository.save(borrow);

        // 4. Ghi nhật ký hệ thống (Audit Log)
        auditMessagePort.sendBorrowEvent(
                "BORROW_UPDATED",
                saved.getBorrowId(),
                "Thủ thư đã hiệu chỉnh thủ công dữ liệu cho bản ghi mượn: " + saved.getBorrowId()
        );

        // 5. Lấy tên sách và tên độc giả bằng cách sử dụng các Port đã tối ưu hóa (batch ports)
        String bookTitle = bookCatalogPort.getBookTitles(Set.of(saved.getBookId()))
                .getOrDefault(saved.getBookId(), "Sách không xác định");

        String readerName = readerRegistryPort.getReaderNames(Set.of(saved.getReaderId()))
                .getOrDefault(saved.getReaderId(), "Độc giả không xác định");

        // 6. Trả về DTO hiển thị chi tiết thông tin sau khi cập nhật
        return new BorrowDetailsView(
                saved.getBorrowId(),
                saved.getReaderId(),
                readerName,
                saved.getBookId(),
                bookTitle,
                saved.getBorrowDate(),
                saved.getDueDate(),
                saved.getReturnDate(),
                saved.getConditionBorrow(),
                saved.getConditionReturn(),
                saved.getStatus(),
                saved.getPrice(),
                saved.getFine(),
                saved.getPaymentStatus()
        );
    }
}