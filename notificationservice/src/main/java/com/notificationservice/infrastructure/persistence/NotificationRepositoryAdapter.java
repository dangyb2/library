package com.notificationservice.infrastructure.persistence;

import com.notificationservice.application.port.out.NotificationRepository;
import com.notificationservice.domain.model.Notification;
import com.notificationservice.domain.model.NotificationStatus;
import com.notificationservice.domain.model.NotificationType;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public class NotificationRepositoryAdapter implements NotificationRepository {
    private final NotificationJpaRepository repository;
    private final NotificationEntityMapper mapper;

    public NotificationRepositoryAdapter(NotificationJpaRepository repository, NotificationEntityMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public Notification save(Notification notification) {
        return mapper.toDomain(repository.save(mapper.toEntity(notification)));
    }

    @Override
    public List<Notification> findFailed(int maxRetry, int limit) {
        PageRequest page = PageRequest.of(0, limit);
        return repository
                .findByStatusAndRetryCountLessThanOrderByCreatedAtAsc(NotificationStatus.FAILED, maxRetry, page)
                .stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Override
    public Optional<Notification> findById(String id) {
        return repository.findById(id).map(mapper::toDomain);
    }

    @Override
    public List<Notification> search(
            String id,
            String recipientEmail,
            NotificationType type,
            NotificationStatus status,
            Instant fromDate,
            Instant toDate
    ) {
        return repository.search(id, recipientEmail, type, status, fromDate, toDate)
                .stream()
                .map(mapper::toDomain)
                .toList();
    }
}
