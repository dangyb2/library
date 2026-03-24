package com.bookservice.application.port.out;

import com.bookservice.application.dto.GenrePredictionResponse;

public interface AiGenrePredictorPort {
    GenrePredictionResponse fetchPrediction(String title, String description);
}