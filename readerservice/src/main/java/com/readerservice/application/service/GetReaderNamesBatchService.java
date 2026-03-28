package com.readerservice.application.service;

import com.readerservice.application.port.in.GetReaderNamesBatchUseCase;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.Reader;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

public class GetReaderNamesBatchService implements GetReaderNamesBatchUseCase {
    private final ReaderRepository readerRepository;

    public GetReaderNamesBatchService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public Map<String, String> getNames(Set<String> ids) {
        if (ids == null || ids.isEmpty()) {
            return Collections.emptyMap();
        }

        Set<String> sanitizedIds = ids.stream()
                .filter(id -> id != null && !id.isBlank())
                .collect(Collectors.toCollection(LinkedHashSet::new));

        if (sanitizedIds.isEmpty()) {
            return Collections.emptyMap();
        }

        Map<String, String> existingNames = readerRepository.findByIds(sanitizedIds)
                .stream()
                .collect(Collectors.toMap(
                        Reader::getId,
                        Reader::getName
                ));

        Map<String, String> response = new LinkedHashMap<>();
        for (String id : sanitizedIds) {
            response.put(id, existingNames.getOrDefault(id, "Unknown Reader"));
        }
        return response;
    }
}
