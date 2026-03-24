package com.borrowservice.infrastructure.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Set;

@FeignClient(name = "book-service", url = "${book.service.url}")
public interface BookFeignClient {

    @GetMapping("/books/{bookId}/available")
    boolean checkAvailability(@PathVariable("bookId") String bookId);

    @PatchMapping("/books/{id}/stock/checkout")
    void checkoutBook(@PathVariable("id") String id);

    @PatchMapping("/books/{id}/stock/return")
    void returnBookStock(@PathVariable("id") String id);

    @GetMapping("/books/batch-titles")
    Map<String, String> getBookTitles(@RequestParam("ids") Set<String> ids);

    // --- Lost & Found Endpoints ---

    @PatchMapping("/books/{id}/stock/lost")
    void markCopyAsLost(@PathVariable("id") String id);

    @PatchMapping("/books/{id}/stock/found")
    void restoreLostCopy(@PathVariable("id") String id);
}