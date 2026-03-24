package com.borrowservice.infrastructure.config;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.infrastructure.persistence.JpaBorrowRepository;
import com.borrowservice.infrastructure.persistence.SpringDataBorrowRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
@Configuration
public class BorrowPersistenceConfig {
    @Bean
    BookBorrowRepository bookBorrowRepository(SpringDataBorrowRepository jpaRepos) {
        return new JpaBorrowRepository(jpaRepos);
    }
}
