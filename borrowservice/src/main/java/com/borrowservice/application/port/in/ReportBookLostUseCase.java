package com.borrowservice.application.port.in;

import com.borrowservice.application.dto.LostReportResult; // Thêm import này
import com.borrowservice.application.port.in.command.ReportLostCommand;

public interface ReportBookLostUseCase {
    // Đổi BigDecimal thành LostReportResult
    LostReportResult report(ReportLostCommand command);
}