package com.readerservice.infrastructure.config;

import com.readerservice.application.port.in.CheckReaderEligibilityUseCase;
import com.readerservice.application.port.in.CreateReaderUseCase;
import com.readerservice.application.port.in.DeleteReaderUseCase;
import com.readerservice.application.port.in.ExtendMembershipUseCase;
import com.readerservice.application.port.in.FindAllReadersUseCase;
import com.readerservice.application.port.in.FindReaderByEmailUseCase;
import com.readerservice.application.port.in.FindReaderByIdUseCase;
import com.readerservice.application.port.in.FindReaderByPhoneUseCase;
import com.readerservice.application.port.in.FindReadersByNameUseCase;
import com.readerservice.application.port.in.FindReadersByStatusUseCase;
import com.readerservice.application.port.in.GetReaderNamesBatchUseCase;
import com.readerservice.application.port.in.NotifyMembershipStatusUseCase;
import com.readerservice.application.port.in.SuspendReaderUseCase;
import com.readerservice.application.port.in.UnsuspendReaderUseCase;
import com.readerservice.application.port.in.UpdateReaderUseCase;
import com.readerservice.application.port.out.AuditMessagePort;
import com.readerservice.application.port.out.CheckReaderBorrowStatusPort;
import com.readerservice.application.port.out.NotificationPort;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.application.service.CheckReaderEligibilityService;
import com.readerservice.application.service.CreateReaderService;
import com.readerservice.application.service.DeleteReaderService;
import com.readerservice.application.service.ExtendMembershipService;
import com.readerservice.application.service.FindAllReadersService;
import com.readerservice.application.service.FindReaderByEmailService;
import com.readerservice.application.service.FindReaderByIdService;
import com.readerservice.application.service.FindReaderByPhoneService;
import com.readerservice.application.service.FindReadersByNameService;
import com.readerservice.application.service.FindReadersByStatusService;
import com.readerservice.application.service.GetReaderNamesBatchService;
import com.readerservice.application.service.NotifyMembershipStatusService;
import com.readerservice.application.service.SuspendReaderService;
import com.readerservice.application.service.UnsuspendReaderService;
import com.readerservice.application.service.UpdateReaderService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ReaderUseCaseConfig {

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

    @Bean
    FindReadersByStatusUseCase findReadersByStatusUseCase(ReaderRepository repository) {
        return new FindReadersByStatusService(repository);
    }

    @Bean
    GetReaderNamesBatchUseCase getReaderNamesBatchUseCase(ReaderRepository repository) {
        return new GetReaderNamesBatchService(repository);
    }

    @Bean
    CheckReaderEligibilityUseCase checkReaderEligibilityUseCase(ReaderRepository repository) {
        return new CheckReaderEligibilityService(repository);
    }

    @Bean
    CreateReaderUseCase createReaderUseCase(ReaderRepository repository,
                                            AuditMessagePort auditMessagePort,
                                            NotificationPort notificationPort) {
        return new CreateReaderService(repository, auditMessagePort, notificationPort);
    }

    @Bean
    UpdateReaderUseCase updateReaderUseCase(ReaderRepository repository,
                                            AuditMessagePort auditMessagePort,
                                            NotificationPort notificationPort) {
        return new UpdateReaderService(repository, auditMessagePort, notificationPort);
    }

    @Bean
    DeleteReaderUseCase deleteReaderUseCase(ReaderRepository repository,
                                            AuditMessagePort auditMessagePort,
                                            NotificationPort notificationPort,
                                            CheckReaderBorrowStatusPort borrowStatusPort) {
        return new DeleteReaderService(
                repository,
                auditMessagePort,
                notificationPort,
                borrowStatusPort
        );
    }

    @Bean
    SuspendReaderUseCase suspendReaderUseCase(ReaderRepository repository,
                                              AuditMessagePort auditMessagePort,
                                              NotificationPort notificationPort) {
        return new SuspendReaderService(repository, auditMessagePort, notificationPort);
    }

    @Bean
    UnsuspendReaderUseCase unsuspendReaderUseCase(ReaderRepository repository,
                                                  AuditMessagePort auditMessagePort,
                                                  NotificationPort notificationPort) {
        return new UnsuspendReaderService(repository, auditMessagePort, notificationPort);
    }

    @Bean
    ExtendMembershipUseCase extendMembershipUseCase(ReaderRepository repository,
                                                    AuditMessagePort auditMessagePort,
                                                    NotificationPort notificationPort) {
        return new ExtendMembershipService(repository, auditMessagePort, notificationPort);
    }

    @Bean
    NotifyMembershipStatusUseCase notifyMembershipStatusUseCase(ReaderRepository repository,
                                                                NotificationPort notificationPort,
                                                                AuditMessagePort auditMessagePort,
                                                                @Value("${reader.membership.expiring-days:3}") int expiringBeforeDays) {
        return new NotifyMembershipStatusService(
                repository,
                notificationPort,
                auditMessagePort,
                expiringBeforeDays
        );
    }
}
