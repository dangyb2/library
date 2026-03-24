package com.borrowservice.application.port.in.command;

import java.time.LocalDate;

public record ReportLostCommand(String borrowId, LocalDate reportDate){
}
