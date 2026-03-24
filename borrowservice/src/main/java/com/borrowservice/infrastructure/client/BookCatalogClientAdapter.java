package com.borrowservice.infrastructure.client;

import com.borrowservice.application.port.out.BookCatalogPort;
import feign.FeignException;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.Map;
import java.util.Set;

@Component
public class BookCatalogClientAdapter implements BookCatalogPort {

    private final BookFeignClient bookFeignClient;

    public BookCatalogClientAdapter(BookFeignClient bookFeignClient) {
        this.bookFeignClient = bookFeignClient;
    }

    @Override
    public boolean isBookAvailable(String bookId) {
        System.out.println("Asking book-service via Feign if available: " + bookId);
        return bookFeignClient.checkAvailability(bookId);
    }

    @Override
    public void markCopyAsLost(String bookId) {
        System.out.println("Telling Book Service a book was LOST: " + bookId);
        // Look how clean this is now! No more Maps or dummy amounts.
        bookFeignClient.markCopyAsLost(bookId);
    }

    @Override
    public void restoreLostCopy(String bookId) {
        System.out.println("Telling Book Service a LOST book was FOUND: " + bookId);
        // So simple.
        bookFeignClient.restoreLostCopy(bookId);
    }

    @Override
    public void decreaseBookStock(String bookId) {
        System.out.println("Telling Book Service to check out book: " + bookId);
        bookFeignClient.checkoutBook(bookId);
    }

    @Override
    public void addBookStock(String bookId) {
        System.out.println("Telling Book Service to return book: " + bookId);
        bookFeignClient.returnBookStock(bookId);
    }

    @Override
    public Map<String, String> getBookTitles(Set<String> bookIds) {
        if (bookIds == null || bookIds.isEmpty()) {
            return Collections.emptyMap();
        }

        try {
            System.out.println("Batch fetching book titles from book-service for IDs: " + bookIds);
            return bookFeignClient.getBookTitles(bookIds);
        } catch (FeignException e) {
            System.err.println("Warning: Book batch endpoint failed. " + e.getMessage());
            return Collections.emptyMap();
        }
    }
}