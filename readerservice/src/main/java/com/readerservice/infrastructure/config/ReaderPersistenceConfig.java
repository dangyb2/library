package com.readerservice.infrastructure.config;

import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.infrastructure.persistence.JpaReaderRepository;
import com.readerservice.infrastructure.persistence.SpringDataReaderRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
    public class ReaderPersistenceConfig {

    @Bean
    ReaderRepository readerRepository(SpringDataReaderRepository jpaRepos) {
        return new JpaReaderRepository(jpaRepos);
    }
}
