package com.borrowservice.infrastructure.client;

import com.borrowservice.application.dto.ReaderEligibilityView;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.ExternalServiceUnavailableException; // <-- Added
import feign.FeignException;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.Map;
import java.util.Set;

@Component
public class ReaderRegistryClientAdapter implements ReaderRegistryPort {

    private final ReaderFeignClient readerFeignClient;

    public ReaderRegistryClientAdapter(ReaderFeignClient readerFeignClient) {
        this.readerFeignClient = readerFeignClient;
    }

    @Override
    public Map<String, String> getReaderNames(Set<String> readerIds) {
        if (readerIds == null || readerIds.isEmpty()) {
            return Collections.emptyMap();
        }

        try {
            return readerFeignClient.getReaderNames(readerIds);
        } catch (FeignException e) {
            System.err.println("Warning: Reader batch endpoint failed or not ready. " + e.getMessage());
            return Collections.emptyMap();
        }
    }
    @Override
    public String getReaderEmail(String readerId) {
        try {
            return readerFeignClient.getReaderEmail(readerId);
        } catch (Exception e) {
            System.err.println("Failed to fetch email for reader " + readerId + ": " + e.getMessage());
            return "unknown@example.com"; // Fallback to prevent crashing if the reader service is down
        }
    }
    @Override
    public ReaderEligibilityView getEligibilityDetails(String readerId) {
        try {
            return readerFeignClient.getEligibilityDetails(readerId);
        } catch (FeignException.NotFound e) {
            return new ReaderEligibilityView(false, null);
        } catch (FeignException e) {
            // Replaced generic InvalidDataException with precise error
            throw new ExternalServiceUnavailableException("Reader Registry Service");
        }
    }
}