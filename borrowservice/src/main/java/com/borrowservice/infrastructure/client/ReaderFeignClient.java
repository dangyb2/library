package com.borrowservice.infrastructure.client;

import com.borrowservice.application.dto.ReaderEligibilityView;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Set;

@FeignClient(name = "reader-service", url = "${reader.service.url}")
public interface ReaderFeignClient {


    @GetMapping("/readers/batch-names")
    Map<String, String> getReaderNames(@RequestParam("ids") Set<String> ids);
    @GetMapping("/readers/{readerId}/eligibility-details")
    ReaderEligibilityView getEligibilityDetails(@PathVariable("readerId") String readerId);
    @GetMapping("/readers/{id}/email")
    String getReaderEmail(@PathVariable("id") String id);
}