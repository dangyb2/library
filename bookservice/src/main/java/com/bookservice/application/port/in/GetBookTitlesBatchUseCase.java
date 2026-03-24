package com.bookservice.application.port.in;

import java.util.Map;
import java.util.Set;

public interface GetBookTitlesBatchUseCase {
    Map<String, String> getTitles(Set<String> bookIds);
}