package com.bookservice.application.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record GenrePredictionResponse(
        List<Prediction> predictions
) {
        public record Prediction(
                String genre,
                double confidence,
                @JsonProperty("is_match") boolean isMatch
        ) {}
}