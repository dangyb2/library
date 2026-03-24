package com.bookservice.application.port.in;

import com.bookservice.application.dto.GenrePredictionResponse;

public interface PredictGenreUseCase {
    GenrePredictionResponse predict(String title, String description);
}