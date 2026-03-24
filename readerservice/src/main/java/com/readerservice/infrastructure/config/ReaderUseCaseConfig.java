package com.readerservice.infrastructure.config;

import com.readerservice.application.port.in.*;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.application.service.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * ReaderUseCaseConfig chịu trách nhiệm cấu hình (wiring)
 * các Use Case (Input Port) cho module Reader.
 *
 * Vai trò:
 * - Kết nối Input Port (interface) với Application Service (implementation)
 * - Đảm bảo Controller chỉ phụ thuộc vào interface, không phụ thuộc class cụ thể
 *
 * Vị trí trong kiến trúc:
 * - Thuộc tầng Infrastructure
 * - Chỉ làm nhiệm vụ cấu hình, KHÔNG chứa logic nghiệp vụ
 *
 * Luồng phụ thuộc:
 * Web Controller
 *     → Use Case (Input Port)
 *         → Application Service
 *             → Repository (Output Port)
 */
@Configuration
public class ReaderUseCaseConfig {

    /**
     * Use case: Tìm độc giả theo id
     */
    @Bean
    FindReaderByIdUseCase findReaderByIdUseCase(ReaderRepository repository) {
        return new FindReaderByIdService(repository);
    }

    @Bean
    FindAllReadersUseCase findAllReadersUseCase(ReaderRepository repository) {
        return new FindAllReadersService(repository);
    }

    @Bean
    FindReaderByEmailUseCase findReaderByEmailUseCase(ReaderRepository repository) {
        return new FindReaderByEmailService(repository);
    }

    @Bean
    FindReaderByPhoneUseCase findReaderByPhoneUseCase(ReaderRepository repository) {
        return new FindReaderByPhoneService(repository);
    }

    @Bean
    FindReadersByNameUseCase findReadersByNameUseCase(ReaderRepository repository) {
        return new FindReadersByNameService(repository);
    }

    /**
     * Use case: Tạo mới độc giả
     */
    @Bean
    CreateReaderUseCase createReaderUseCase(ReaderRepository repository) {
        return new CreateReaderService(repository);
    }

    /**
     * Use case: Đình chỉ độc giả
     */
    @Bean
    SuspendReaderUseCase suspendReaderUseCase(ReaderRepository repository) {
        return new SuspendReaderService(repository);
    }

    /**
     * Use case: Gỡ đình chỉ độc giả
     */
    @Bean
    UnsuspendReaderUseCase unsuspendReaderUseCase(ReaderRepository repository) {
        return new UnsuspendReaderService(repository);
    }

    /**
     * Use case: Gia hạn thẻ thành viên
     */
    @Bean
    ExtendMembershipUseCase extendMembershipUseCase(ReaderRepository repository) {
        return new ExtendMembershipService(repository);
    }
}
