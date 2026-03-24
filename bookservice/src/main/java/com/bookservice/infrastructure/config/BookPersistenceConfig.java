package com.bookservice.infrastructure.config;

import com.bookservice.application.port.out.BookRepository;
import com.bookservice.infrastructure.persistence.JpaBookRepository;
import com.bookservice.infrastructure.persistence.SpringDataBookRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class BookPersistenceConfig {
    @Bean
    BookRepository bookRepository(SpringDataBookRepository jpaRepos) {
        return new JpaBookRepository(jpaRepos);
    }
}
