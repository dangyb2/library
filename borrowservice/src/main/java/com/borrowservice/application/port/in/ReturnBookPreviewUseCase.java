package com.borrowservice.application.port.in;

import com.borrowservice.application.port.in.command.ReturnPreviewCommand;
import com.borrowservice.application.dto.ReturnPreviewResult;

public interface ReturnBookPreviewUseCase {
    ReturnPreviewResult preview(ReturnPreviewCommand command);
}