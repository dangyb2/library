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
    public List<Notification> findByStatus(NotificationStatus status) {
        return repository.findByStatus(status).stream()
                .map(mapper::toDomain)
                .toList();
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
    public List<Notification> findByType(NotificationType type) {
        return repository.findByType(type).stream()
                .map(mapper::toDomain)
                .toList();
    }
    @Override
    public List<Notification> findByRecipientEmail(String email) {
        return repository.findByRecipientEmail(email).stream() // Assuming your JpaRepository has this method
                .map(mapper::toDomain)
                .toList();
    }
    @Override
    public List<Notification> findAll() {
        return repository.findAll().stream()
                .map(mapper::toDomain) // Converts the DB Entity back to your Domain Model
                .toList();
    }
    @Override
    public List<Notification> findByDateRange(Instant startDate, Instant endDate) {
        return repository.findByCreatedAtBetween(startDate, endDate).stream()
                .map(mapper::toDomain)
                .toList();
    }
}
