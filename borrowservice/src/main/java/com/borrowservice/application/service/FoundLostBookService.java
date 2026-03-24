package com.borrowservice.application.service;

import com.borrowservice.application.port.in.FoundLostBookUseCase;
import com.borrowservice.application.port.in.command.FoundLostBookCommand;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import com.borrowservice.domain.model.Borrow;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

import static com.borrowservice.application.util.CurrencyFormatter.formatVND;

/**
 * Dịch vụ xử lý khi một cuốn sách (từng bị báo mất) được tìm thấy và trả lại.
 */
@Transactional
public class FoundLostBookService extends BaseBorrowService implements FoundLostBookUseCase {

    private final BookBorrowRepository bookBorrowRepository;
    private final AuditMessagePort auditMessagePort;

    public FoundLostBookService(BookBorrowRepository bookBorrowRepository,
                                AuditMessagePort auditMessagePort,
                                BookCatalogPort bookCatalogPort,
                                ReaderRegistryPort readerRegistryPort) {
        super(bookCatalogPort, readerRegistryPort); // Gọi constructor của lớp cha
        this.bookBorrowRepository = bookBorrowRepository;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public BigDecimal markFound(FoundLostBookCommand command) {
        // Tìm kiếm bản ghi mượn sách, ném lỗi nếu không tồn tại
        Borrow borrow = bookBorrowRepository.findById(command.borrowId())
                .orElseThrow(() -> BorrowRecordNotFoundException.byRecordId(command.borrowId()));

        // 1. Cập nhật trạng thái và tính toán lại tiền phạt trong tầng Domain
        borrow.markFound(command.foundDate());

        // 2. Lấy số tiền phạt mới đã được cập nhật
        BigDecimal updatedFine = borrow.getFine();

        // 3. Lưu thay đổi vào cơ sở dữ liệu
        bookBorrowRepository.save(borrow);

        // 4. Khôi phục lại bản sao sách trong danh mục (Inventory)
        // SỬA LỖI: Cập nhật để khớp với phương thức domain đơn lẻ mới trong BookCatalogPort
        bookCatalogPort.restoreLostCopy(borrow.getBookId());

        String bookTitle = getBookTitle(borrow.getBookId());
        String readerName = getReaderName(borrow.getReaderId());

        // 5. Gửi nhật ký hệ thống (Audit log)
        auditMessagePort.sendBorrowEvent(
                "BOOK_FOUND",
                borrow.getBorrowId(),
                String.format("%s đã tìm thấy và trả lại cuốn sách '%s' (trước đó đã báo mất). Tiền phạt được tính lại: %s",
                        readerName, bookTitle, formatVND(updatedFine))
        );

        return updatedFine;
    }
}