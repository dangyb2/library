package com.readerservice.infrastructure.web;

import com.readerservice.application.dto.ReaderEligibilityView;
import com.readerservice.application.dto.ReaderView;
import com.readerservice.application.port.in.CheckReaderEligibilityUseCase;
import com.readerservice.application.port.in.CreateReaderUseCase;
import com.readerservice.application.port.in.DeleteReaderUseCase;
import com.readerservice.application.port.in.ExtendMembershipUseCase;
import com.readerservice.application.port.in.FindAllReadersUseCase;
import com.readerservice.application.port.in.FindReaderByEmailUseCase;
import com.readerservice.application.port.in.FindReaderByIdUseCase;
import com.readerservice.application.port.in.FindReaderByPhoneUseCase;
import com.readerservice.application.port.in.FindReadersByNameUseCase;
import com.readerservice.application.port.in.FindReadersByStatusUseCase;
import com.readerservice.application.port.in.GetReaderNamesBatchUseCase;
import com.readerservice.application.port.in.SuspendReaderUseCase;
import com.readerservice.application.port.in.UnsuspendReaderUseCase;
import com.readerservice.application.port.in.UpdateReaderUseCase;
import com.readerservice.domain.model.Status;
import com.readerservice.infrastructure.dto.CreateReaderRequest;
import com.readerservice.infrastructure.dto.ExtendMemberShipRequest;
import com.readerservice.infrastructure.dto.SuspendRequest;
import com.readerservice.infrastructure.dto.UpdateReaderRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@Validated
@RequestMapping("/readers")
public class ReaderController {
    private final FindAllReadersUseCase findAllReadersUseCase;
    private final FindReaderByIdUseCase findReaderByIdUseCase;
    private final FindReaderByEmailUseCase findReaderByEmailUseCase;
    private final FindReaderByPhoneUseCase findReaderByPhoneUseCase;
    private final FindReadersByNameUseCase findReadersByNameUseCase;
    private final FindReadersByStatusUseCase findReadersByStatusUseCase;
    private final GetReaderNamesBatchUseCase getReaderNamesBatchUseCase;
    private final CheckReaderEligibilityUseCase checkReaderEligibilityUseCase;
    private final CreateReaderUseCase createReaderUseCase;
    private final UpdateReaderUseCase updateReaderUseCase;
    private final DeleteReaderUseCase deleteReaderUseCase;
    private final SuspendReaderUseCase suspendReaderUseCase;
    private final UnsuspendReaderUseCase unsuspendReaderUseCase;
    private final ExtendMembershipUseCase extendMembershipUseCase;

    public ReaderController(FindAllReadersUseCase findAllReadersUseCase,
                            FindReaderByIdUseCase findReaderByIdUseCase,
                            FindReaderByEmailUseCase findReaderByEmailUseCase,
                            FindReaderByPhoneUseCase findReaderByPhoneUseCase,
                            FindReadersByNameUseCase findReadersByNameUseCase,
                            FindReadersByStatusUseCase findReadersByStatusUseCase,
                            GetReaderNamesBatchUseCase getReaderNamesBatchUseCase,
                            CheckReaderEligibilityUseCase checkReaderEligibilityUseCase,
                            CreateReaderUseCase createReaderUseCase,
                            UpdateReaderUseCase updateReaderUseCase,
                            DeleteReaderUseCase deleteReaderUseCase,
                            SuspendReaderUseCase suspendReaderUseCase,
                            UnsuspendReaderUseCase unsuspendReaderUseCase,
                            ExtendMembershipUseCase extendMembershipUseCase) {
        this.findAllReadersUseCase = findAllReadersUseCase;
        this.findReaderByIdUseCase = findReaderByIdUseCase;
        this.findReaderByEmailUseCase = findReaderByEmailUseCase;
        this.findReaderByPhoneUseCase = findReaderByPhoneUseCase;
        this.findReadersByNameUseCase = findReadersByNameUseCase;
        this.findReadersByStatusUseCase = findReadersByStatusUseCase;
        this.getReaderNamesBatchUseCase = getReaderNamesBatchUseCase;
        this.checkReaderEligibilityUseCase = checkReaderEligibilityUseCase;
        this.createReaderUseCase = createReaderUseCase;
        this.updateReaderUseCase = updateReaderUseCase;
        this.deleteReaderUseCase = deleteReaderUseCase;
        this.suspendReaderUseCase = suspendReaderUseCase;
        this.unsuspendReaderUseCase = unsuspendReaderUseCase;
        this.extendMembershipUseCase = extendMembershipUseCase;
    }

    @GetMapping
    public List<ReaderView> findAll() {
        return findAllReadersUseCase.findAll();
    }

    @GetMapping("/{id}")
    public ReaderView findById(@PathVariable String id) {
        return findReaderByIdUseCase.find(id);
    }

    @GetMapping("/by-email")
    public ReaderView findByEmail(@RequestParam("email")
                                  @NotBlank(message = "Email must not be blank")
                                  @Email(message = "Email format is invalid") String email) {
        return findReaderByEmailUseCase.findByEmail(email);
    }

    @GetMapping("/by-phone")
    public ReaderView findByPhone(@RequestParam("phone")
                                  @NotBlank(message = "Phone must not be blank")
                                  @Pattern(regexp = "^\\+?[0-9 .-]{8,20}$", message = "Phone format is invalid") String phone) {
        return findReaderByPhoneUseCase.findByPhone(phone);
    }

    @GetMapping("/by-name")
    public List<ReaderView> findByName(@RequestParam("name") @NotBlank(message = "Name must not be blank") String name) {
        return findReadersByNameUseCase.findByName(name);
    }

    @GetMapping("/by-status")
    public List<ReaderView> findByStatus(
            @RequestParam("status") Status status) {
        return findReadersByStatusUseCase.findByStatus(status);
    }
    @PostMapping
    public ResponseEntity<Map<String, String>> create(
            @RequestBody @Valid CreateReaderRequest request) {

        String id = createReaderUseCase.create(
                request.name(),
                request.email(),
                request.phone(),
                request.membershipExpireAt()
        );

        return ResponseEntity
                .created(URI.create("/readers/" + id))
                .body(Map.of("id", id));
    }
    @PutMapping("/{id}")
    public ReaderView update(@PathVariable String id,
                             @RequestBody @Valid UpdateReaderRequest request) {
        return updateReaderUseCase.update(
                id,
                request.name(),
                request.email(),
                request.phone()
        );
    }
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String id) {
        deleteReaderUseCase.delete(id);
    }
    @PostMapping("/{id}/suspend")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void suspend(@PathVariable String id,
                        @RequestBody @Valid SuspendRequest request) {
        suspendReaderUseCase.suspend(id, request.reason());
    }

    @PostMapping("/{id}/unsuspend")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void unsuspend(@PathVariable String id) {
        unsuspendReaderUseCase.unsuspend(id);
    }

    @PostMapping("/{id}/extend-membership")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void extendMembership(@PathVariable String id,
                                 @RequestBody @Valid ExtendMemberShipRequest request) {
        extendMembershipUseCase.extend(id, request.newExpireDate());
    }
    @GetMapping("/batch-names")
    public Map<String, String> getBatchNames(@RequestParam("ids") Set<String> ids) {
        return getReaderNamesBatchUseCase.getNames(ids);
    }

    @GetMapping("/{readerId}/eligibility-details")
    public ReaderEligibilityView getEligibilityDetails(@PathVariable String readerId) {
        return checkReaderEligibilityUseCase.check(readerId);
    }

    @GetMapping("/{id}/email")
    public String getReaderEmail(@PathVariable String id) {
        ReaderView reader = findReaderByIdUseCase.find(id);
        return reader.email();
    }
}
