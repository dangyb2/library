package com.notificationservice.infrastructure.persistence;

import com.notificationservice.domain.model.NotificationStatus;
import com.notificationservice.domain.model.NotificationType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface NotificationJpaRepository extends JpaRepository<NotificationEntity, String> {
    List<NotificationEntity> findByStatusAndRetryCountLessThanOrderByCreatedAtAsc(
            NotificationStatus status,
            int retryCount,
            Pageable pageable
    );

    @Query("""
            select n
            from NotificationEntity n
            where (:id is null or n.id = :id)
              and (:recipientEmail is null or lower(n.recipientEmail) like lower(concat('%', :recipientEmail, '%')))
              and (:type is null or n.type = :type)
              and (:status is null or n.status = :status)
              and (:fromDate is null or n.createdAt >= :fromDate)
              and (:toDate is null or n.createdAt <= :toDate)
            order by n.createdAt desc
            """)
    List<NotificationEntity> search(
            @Param("id") String id,
            @Param("recipientEmail") String recipientEmail,
            @Param("type") NotificationType type,
            @Param("status") NotificationStatus status,
            @Param("fromDate") Instant fromDate,
            @Param("toDate") Instant toDate
    );
}
