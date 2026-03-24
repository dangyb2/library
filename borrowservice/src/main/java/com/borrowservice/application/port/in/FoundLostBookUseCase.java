package com.borrowservice.application.port.in;

import com.borrowservice.application.port.in.command.FoundLostBookCommand;
import java.math.BigDecimal;

public interface FoundLostBookUseCase {
    BigDecimal markFound(FoundLostBookCommand command);
}