package com.readerservice.infrastructure.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "borrowservice", url = "${borrow-service.url:http://localhost:8083}")
public interface BorrowFeignClient {

    // Removed /api/v1 to match the BorrowController's @RequestMapping("/borrows")
    @GetMapping("/borrows/reader/{readerId}/has-active")
    boolean hasActiveBorrowsOrFines(@PathVariable("readerId") String readerId);
}