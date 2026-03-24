package com.borrowservice.application.port.out;

import com.borrowservice.application.dto.ReaderEligibilityView;

import java.util.Map;
import java.util.Set;

public interface ReaderRegistryPort {
    Map<String, String> getReaderNames(Set<String> readerIds);
    ReaderEligibilityView getEligibilityDetails(String readerId);

    String getReaderEmail(String readerId);
}