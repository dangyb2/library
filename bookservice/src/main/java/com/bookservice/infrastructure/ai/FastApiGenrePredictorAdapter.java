package com.bookservice.infrastructure.ai;

import com.bookservice.application.dto.GenrePredictionResponse;
import com.bookservice.application.port.out.AiGenrePredictorPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

import static java.util.Map.entry;

@Component
public class FastApiGenrePredictorAdapter implements AiGenrePredictorPort {

    private static final Logger log = LoggerFactory.getLogger(FastApiGenrePredictorAdapter.class);

    private final RestClient restClient;
    private final String fastApiUrl;

    private static final Map<String, String> GENRE_MAPPING = Map.ofEntries(
            entry("anthology", "Anthology"),
            entry("art_music", "Art & Music"),
            entry("audience_adult", "Adult"),
            entry("audience_childrens", "Children's"),
            entry("audience_juvenile", "Juvenile"),
            entry("audience_young_adult", "Young Adult"),
            entry("biography_memoir", "Biography & Memoir"),
            entry("business", "Business"),
            entry("classic", "Classic"),
            entry("comics_graphic_novels", "Comics & Graphic Novels"),
            entry("cooking", "Cooking"),
            entry("drama", "Drama"),
            entry("essay", "Essay"),
            entry("fantasy", "Fantasy"),
            entry("historical_fiction", "Historical Fiction"),
            entry("history", "History"),
            entry("horror", "Horror"),
            entry("literary_fiction", "Literary Fiction"),
            entry("philosophy", "Philosophy"),
            entry("poetry", "Poetry"),
            entry("politics", "Politics"),
            entry("religion", "Religion"),
            entry("romance", "Romance"),
            entry("science", "Science"),
            entry("science_fiction", "Science Fiction"),
            entry("self_help", "Self-Help"),
            entry("sports", "Sports"),
            entry("technology", "Technology"),
            entry("thriller", "Thriller"),
            entry("travel", "Travel"),
            entry("type_fiction", "Fiction"),
            entry("type_nonfiction", "Non-Fiction"),
            entry("western", "Western")
    );

    public FastApiGenrePredictorAdapter(@Value("${fastapi.predictor.url}") String fastApiUrl) {
        this.fastApiUrl = fastApiUrl;
        this.restClient = RestClient.create();
    }

    @Override
    public GenrePredictionResponse fetchPrediction(String title, String description) {
        try {
            GenrePredictionResponse response = restClient.post()
                    .uri(fastApiUrl)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of("title", title, "description", description))
                    .retrieve()
                    .body(GenrePredictionResponse.class);

            if (response == null || response.predictions() == null) {
                return new GenrePredictionResponse(List.of());
            }

            List<GenrePredictionResponse.Prediction> cleaned = response.predictions().stream()
                    .map(p -> new GenrePredictionResponse.Prediction(
                            formatGenreString(p.genre()),
                            p.confidence(),
                            p.isMatch() //
                    ))
                    .toList();

            return new GenrePredictionResponse(cleaned);

        } catch (Exception e) {
            log.error("AI Service failed for '{}': {}", title, e.getMessage());
            return new GenrePredictionResponse(List.of());
        }
    }

    private String formatGenreString(String rawGenre) {
        if (rawGenre == null) return "";
        return GENRE_MAPPING.getOrDefault(rawGenre.toLowerCase(), rawGenre);
    }
}