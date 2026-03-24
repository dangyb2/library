package com.borrowservice.infrastructure.persistence;

import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.domain.model.Borrow;
import com.borrowservice.domain.model.PaymentStatus;
import com.borrowservice.domain.model.Status;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

public class JpaBorrowRepository implements BookBorrowRepository {

    private final SpringDataBorrowRepository repository;
    public JpaBorrowRepository(SpringDataBorrowRepository repository ) {
        this.repository = repository;
    }

    @Override
    public List<Borrow> findAll() {
        return repository.findAll()
                .stream()
                .map(BorrowMapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public Borrow save(Borrow borrow) {
        BorrowEntity entity = BorrowMapper.toEntity(borrow);
        BorrowEntity savedEntity = repository.save(entity);
        return BorrowMapper.toDomain(savedEntity);
    }
    @Override
    public boolean existsByReaderIdAndPaymentStatus(String readerId, PaymentStatus paymentStatus) {
        return repository.existsByReaderIdAndPaymentStatus(readerId, paymentStatus);
    }
    @Override
    public Optional<Borrow> findById(String borrowId) {
        return repository.findById(borrowId)
                .map(BorrowMapper::toDomain);
    }

    @Override
    public List<Borrow> findOverdueBorrows(LocalDate currentDate) {
        return repository.findByStatusAndDueDateBefore(Status.BORROWED, currentDate)
                .stream()
                .map(BorrowMapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public List<Borrow> findByReaderId(String readerId) {
        return repository.findByReaderId(readerId)
                .stream()
                .map(BorrowMapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public List<Borrow> findByReaderIdAndStatus(String readerId, Status status) {
        return repository.findByReaderIdAndStatus(readerId, status)
                .stream()
                .map(BorrowMapper::toDomain)
                .collect(Collectors.toList());
    }
    @Override
    public Optional<Borrow> findByReaderIdAndBookIdAndStatus(String readerId, String bookId, Status status) {
        return repository
                .findByReaderIdAndBookIdAndStatus(readerId, bookId,status)
                .map(BorrowMapper::toDomain);
    }
    @Override
    public long countByReaderIdAndStatus(String readerId, Status status) {
        return repository.countByReaderIdAndStatus(readerId, status);
    }
}