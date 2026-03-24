package com.borrowservice.infrastructure.persistence;

import com.borrowservice.domain.model.Borrow;

public class BorrowMapper {

    public static BorrowEntity toEntity(Borrow borrow) {
        if (borrow == null) {
            return null;
        }

        return new BorrowEntity(
                borrow.getBorrowId(),
                borrow.getReaderId(),
                borrow.getBookId(),
                borrow.getBorrowDate(),
                borrow.getDueDate(),
                borrow.getReturnDate(),
                borrow.getConditionBorrow(),
                borrow.getConditionReturn(),
                borrow.getStatus(),
                borrow.getPrice(),
                borrow.getFine(),
                borrow.getPaymentStatus() //
        );
    }

    /**
     * Maps the JPA Entity back to the rich Domain Model for application use.
     */
    public static Borrow toDomain(BorrowEntity entity) {
        if (entity == null) {
            return null;
        }

        // We use a dedicated "reconstitute" method to bypass business logic
        // and restore the exact state from the database.
        return Borrow.reconstitute(
                entity.getBorrowId(),
                entity.getReaderId(),
                entity.getBookId(),
                entity.getBorrowDate(),
                entity.getDueDate(),
                entity.getReturnDate(),
                entity.getConditionBorrow(),
                entity.getConditionReturn(),
                entity.getStatus(),
                entity.getPrice(),
                entity.getFine(),
                entity.getPaymentStatus()
        );
    }
}