package com.readerservice.infrastructure.client;

import com.readerservice.application.port.out.CheckReaderBorrowStatusPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class BorrowServiceClientAdapter implements CheckReaderBorrowStatusPort {

    private static final Logger log = LoggerFactory.getLogger(BorrowServiceClientAdapter.class);
    private final BorrowFeignClient borrowFeignClient;

    public BorrowServiceClientAdapter(BorrowFeignClient borrowFeignClient) {
        this.borrowFeignClient = borrowFeignClient;
    }

    @Override
    public boolean hasActiveBorrowsOrFines(String readerId) {
        try {
            log.info("Gọi Borrow Service để kiểm tra trạng thái mượn của độc giả: {}", readerId);
            return borrowFeignClient.hasActiveBorrowsOrFines(readerId);
        } catch (Exception e) {
            log.error("Lỗi khi kết nối tới Borrow Service cho độc giả {}: {}", readerId, e.getMessage());
            // An toàn là trên hết: Nếu mất kết nối, từ chối cho phép xóa
            return true;
        }
    }
}