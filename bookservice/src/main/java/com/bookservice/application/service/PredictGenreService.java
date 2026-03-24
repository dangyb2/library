package com.bookservice.application.service;

import com.bookservice.application.dto.GenrePredictionResponse;
import com.bookservice.application.port.in.PredictGenreUseCase;
import com.bookservice.application.port.out.AiGenrePredictorPort;

public class PredictGenreService implements PredictGenreUseCase {

    private final AiGenrePredictorPort aiPort;

    public PredictGenreService(AiGenrePredictorPort aiPort) {
        this.aiPort = aiPort;
    }

    @Override
    public GenrePredictionResponse predict(String title, String description) {
        return aiPort.fetchPrediction(title, description);
    }
}