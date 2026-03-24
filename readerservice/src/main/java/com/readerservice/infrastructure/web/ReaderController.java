package com.readerservice.infrastructure.web;

import com.readerservice.application.dto.ReaderEligibilityView;
import com.readerservice.application.dto.ReaderView;
import com.readerservice.domain.exception.ReaderNotFoundException;
import com.readerservice.application.port.in.*;
import com.readerservice.infrastructure.dto.CreateReaderRequest;
import com.readerservice.infrastructure.dto.ExtendMemberShipRequest;
import com.readerservice.infrastructure.dto.SuspendRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
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
    private final CreateReaderUseCase createReaderUseCase;
    private final SuspendReaderUseCase suspendReaderUseCase;
    private final UnsuspendReaderUseCase unsuspendReaderUseCase;
    private final ExtendMembershipUseCase extendMembershipUseCase;

    public ReaderController(FindAllReadersUseCase findAllReadersUseCase,
                            FindReaderByIdUseCase findReaderByIdUseCase,
                            FindReaderByEmailUseCase findReaderByEmailUseCase,
                            FindReaderByPhoneUseCase findReaderByPhoneUseCase,
                            FindReadersByNameUseCase findReadersByNameUseCase,
                            CreateReaderUseCase createReaderUseCase,
                            SuspendReaderUseCase suspendReaderUseCase,
                            UnsuspendReaderUseCase unsuspendReaderUseCase,
                            ExtendMembershipUseCase extendMembershipUseCase) {
        this.findAllReadersUseCase = findAllReadersUseCase;
        this.findReaderByIdUseCase = findReaderByIdUseCase;
        this.findReaderByEmailUseCase = findReaderByEmailUseCase;
        this.findReaderByPhoneUseCase = findReaderByPhoneUseCase;
        this.findReadersByNameUseCase = findReadersByNameUseCase;
        this.createReaderUseCase = createReaderUseCase;
        this.suspendReaderUseCase = suspendReaderUseCase;
        this.unsuspendReaderUseCase = unsuspendReaderUseCase;
        this.extendMembershipUseCase = extendMembershipUseCase;
    }

    /**
     * API lấy toàn bộ độc giả.
     */
    @GetMapping
    public List<ReaderView> findAll() {
        return findAllReadersUseCase.findAll();
    }

    @GetMapping("/{id}")
    public ReaderView findById(@PathVariable String id){
        return findReaderByIdUseCase.find(id);
    }

    @GetMapping("/by-email")
    public ReaderView findByEmail(@RequestParam("email") @NotBlank(message = "Email must not be blank") @Email(message = "Email format is invalid") String email) {
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


    @PostMapping
    public String create(@RequestBody @Valid CreateReaderRequest request) {
        return createReaderUseCase.create(
                request.name(),
                request.email(),
                request.phone(),
                request.membershipExpireAt()
        );
    }

    /**
     * API đình chỉ một độc giả theo id với lý do cụ thể.
     */
    @PostMapping("/{id}/suspend")
    public void suspend(@PathVariable String id,
                        @RequestBody @Valid SuspendRequest request) {
        suspendReaderUseCase.suspend(id, request.reason());
    }


    @PostMapping("/{id}/unsuspend")
    public void unsuspend(@PathVariable String id) {
        unsuspendReaderUseCase.unsuspend(id);
    }

    @PostMapping("/{id}/extend-membership")
    public void extendMembership(@PathVariable String id,
                                 @RequestBody @Valid ExtendMemberShipRequest request) {
        extendMembershipUseCase.extend(id, request.newExpireDate());
    }
    @GetMapping("/batch-names")
    public Map<String, String> getBatchNames(@RequestParam("ids") Set<String> ids) {
        Map<String, String> readerNames = new HashMap<>();

        for (String id : ids) {
            try {
                ReaderView reader = findReaderByIdUseCase.find(id);
                readerNames.put(id, reader.name());
            } catch (ReaderNotFoundException e) {
                readerNames.put(id, "Unknown Reader");
            }
        }

        return readerNames;
    }
    @GetMapping("/{readerId}/eligibility-details")
    public ReaderEligibilityView getEligibilityDetails(@PathVariable String readerId) {
        ReaderView reader = findReaderByIdUseCase.find(readerId);

        boolean eligible =
                "NORMAL".equals(reader.status()) &&
                        !reader.membershipExpireAt().isBefore(LocalDate.now());

        return new ReaderEligibilityView(
                eligible,
                reader.membershipExpireAt()
        );
    }

    @GetMapping("/{id}/email")
    public String getReaderEmail(@PathVariable String id) {
        ReaderView reader = findReaderByIdUseCase.find(id);
        return reader.email();
    }
}
