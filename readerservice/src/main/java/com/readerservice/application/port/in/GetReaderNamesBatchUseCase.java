package com.readerservice.application.port.in;

import java.util.Map;
import java.util.Set;

public interface GetReaderNamesBatchUseCase {
    Map<String, String> getNames(Set<String> ids);
}
