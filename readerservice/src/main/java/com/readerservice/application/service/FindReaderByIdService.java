package com.readerservice.application.service;

import com.readerservice.application.dto.ReaderView;
import com.readerservice.domain.exception.ReaderNotFoundException;
import com.readerservice.application.port.in.FindReaderByIdUseCase;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.Reader;

/**
 * FindReaderByIdService là Application Service
 * triển khai use case "Tìm độc giả theo id".
 *
 * Vai trò trong kiến trúc:
 * - Nằm ở tầng Application
 * - Triển khai Input Port (FindReaderByIdUseCase)
 * - Điều phối luồng nghiệp vụ (orchestration)
 */
public class    FindReaderByIdService implements FindReaderByIdUseCase {

    private final ReaderRepository readerRepository;

    /**
     * ReaderRepository là Output Port,
     * được inject từ tầng Infrastructure thông qua configuration.
     */
    public FindReaderByIdService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    /**
     * Thực hiện use case tìm độc giả theo id.
     *
     * @param id định danh của độc giả
     * @return Optional chứa Reader nếu tồn tại,
     *         hoặc Optional.empty() nếu không tìm thấy
     */
    @Override
    public ReaderView find(String id) {
        Reader reader = readerRepository.findById(id)
                .orElseThrow(()->new ReaderNotFoundException(id));
        return ReaderView.from(reader);
    }

}
