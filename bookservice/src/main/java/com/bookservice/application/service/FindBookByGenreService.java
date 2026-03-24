package com.bookservice.application.service;

import com.bookservice.application.dto.BookSummaryView;
import com.bookservice.application.port.in.FindBookByGenreUseCase;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.InvalidBookDataException;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
@Transactional(readOnly = true)
public class FindBookByGenreService implements FindBookByGenreUseCase {

    private final BookRepository repository;

    public FindBookByGenreService(BookRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<BookSummaryView> findIgnoreCase(String genre) {
        if (genre == null || genre.isBlank()) {
            throw new InvalidBookDataException("Thể loại không được để trống");
        }
        genre = genre.trim();

        return repository.findByGenreIgnoreCase(genre)
                .stream()
                .map(BookSummaryView::fromBook)
                .toList();
    }
}