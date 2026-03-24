package com.bookservice.application.port.in;

import com.bookservice.application.dto.TotalStockDecreaseView;
import com.bookservice.application.port.in.command.DecreaseTotalStockCommand;

public interface DecreaseTotalStockUseCase {
    TotalStockDecreaseView decrease(String bookId, DecreaseTotalStockCommand command);
}