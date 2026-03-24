package com.bookservice.infrastructure.web;

import com.bookservice.application.dto.BookDetailView;
import com.bookservice.application.dto.BookSummaryView;
import com.bookservice.application.dto.GenrePredictionResponse;
import com.bookservice.application.dto.TotalStockDecreaseView;
import com.bookservice.application.port.in.*;
import com.bookservice.application.port.in.command.CreateBookCommand;
import com.bookservice.application.port.in.command.DecreaseTotalStockCommand;
import com.bookservice.application.port.in.command.UpdateBookCommand;
import com.bookservice.infrastructure.dto.GenrePredictionRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/books")
public class BookController {

    private final AddBookStockUseCase addBookStockUseCase;
    private final CreateBookUseCase createBookUseCase;
    private final CheckoutBookUseCase checkoutBookUseCase;
    private final FindBookByAuthorUseCase findBookByAuthorUseCase;
    private final ReturnBookUseCase returnBookUseCase;
    private final FindBookByGenreUseCase findBookByGenreUseCase;
    private final FindBookByIdUseCase findBookByIdUseCase;
    private final FindBookByIsbnUseCase findBookByIsbnUseCase;
    private final FindBookByTitleUseCase findBookByTitleUseCase;
    private final FindLowStockBookUseCase findLowStockBookUseCase;
    private final GetAllBooksUseCase getAllBooksUseCase;
    private final PredictGenreUseCase predictGenreUseCase;
    private final UpdateBookUseCase updateBookUseCase;
    private final DeleteBookUseCase deleteBookUseCase;
    private final DecreaseTotalStockUseCase decreaseTotalStockUseCase;
    private final GetBookTitlesBatchUseCase getBookTitlesBatchUseCase;
    private final GetArchivedBooksUseCase getArchivedBooksUseCase;
    private final RestoreBookUseCase restoreBookUseCase;

    // --> NEW: Declare your two new use cases here
    private final MarkBookLostUseCase markBookLostUseCase;
    private final RestoreLostBookUseCase restoreLostBookUseCase;

    // --> NEW: Add them to the constructor
    public BookController(AddBookStockUseCase addBookStockUseCase, CreateBookUseCase createBookUseCase, CheckoutBookUseCase checkoutBookUseCase, FindBookByAuthorUseCase findBookByAuthorUseCase, ReturnBookUseCase returnBookUseCase, FindBookByGenreUseCase findBookByGenreUseCase, FindBookByIdUseCase findBookByIdUseCase, FindBookByIsbnUseCase findBookByIsbnUseCase, FindBookByTitleUseCase findBookByTitleUseCase, FindLowStockBookUseCase findLowStockBookUseCase, GetAllBooksUseCase getAllBooksUseCase, PredictGenreUseCase predictGenreUseCase, UpdateBookUseCase updateBookUseCase, DeleteBookUseCase deleteBookUseCase, DecreaseTotalStockUseCase decreaseTotalStockUseCase, GetBookTitlesBatchUseCase getBookTitlesBatchUseCase, GetArchivedBooksUseCase getArchivedBooksUseCase, RestoreBookUseCase restoreBookUseCase, MarkBookLostUseCase markBookLostUseCase, RestoreLostBookUseCase restoreLostBookUseCase) {
        this.addBookStockUseCase = addBookStockUseCase;
        this.createBookUseCase = createBookUseCase;
        this.checkoutBookUseCase = checkoutBookUseCase;
        this.findBookByAuthorUseCase = findBookByAuthorUseCase;
        this.returnBookUseCase = returnBookUseCase;
        this.findBookByGenreUseCase = findBookByGenreUseCase;
        this.findBookByIdUseCase = findBookByIdUseCase;
        this.findBookByIsbnUseCase = findBookByIsbnUseCase;
        this.findBookByTitleUseCase = findBookByTitleUseCase;
        this.findLowStockBookUseCase = findLowStockBookUseCase;
        this.getAllBooksUseCase = getAllBooksUseCase;
        this.predictGenreUseCase = predictGenreUseCase;
        this.updateBookUseCase = updateBookUseCase;
        this.deleteBookUseCase = deleteBookUseCase;
        this.decreaseTotalStockUseCase = decreaseTotalStockUseCase;
        this.getBookTitlesBatchUseCase = getBookTitlesBatchUseCase;
        this.getArchivedBooksUseCase = getArchivedBooksUseCase;
        this.restoreBookUseCase = restoreBookUseCase;

        // --> NEW: Assign them
        this.markBookLostUseCase = markBookLostUseCase;
        this.restoreLostBookUseCase = restoreLostBookUseCase;
    }

    @PatchMapping("/{id}/stock/add-inventory")
    public ResponseEntity<BookDetailView> addStock(@PathVariable String id, @RequestParam long amount) {
        return ResponseEntity.ok(addBookStockUseCase.add(id, amount));
    }

    @PatchMapping("/{id}/stock/return")
    public ResponseEntity<BookDetailView> returnBookStock(@PathVariable String id) {
        return ResponseEntity.ok(returnBookUseCase.returnBook(id));
    }

    @PostMapping
    public ResponseEntity<BookDetailView> createBook(@RequestBody CreateBookCommand command) {
        BookDetailView createdBook = createBookUseCase.create(command);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdBook);
    }

    @PatchMapping("/{id}/stock/remove-inventory")
    public ResponseEntity<TotalStockDecreaseView> removeCopies(
            @PathVariable String id,
            @RequestBody DecreaseTotalStockCommand command) {
        return ResponseEntity.ok(decreaseTotalStockUseCase.decrease(id, command));
    }

    @PatchMapping("/{id}/stock/checkout")
    public ResponseEntity<BookDetailView> decreaseStock(@PathVariable String id) {
        return ResponseEntity.ok(checkoutBookUseCase.checkout(id));
    }

    // --- NEW ENDPOINTS ---

    @PatchMapping("/{id}/stock/lost")
    public ResponseEntity<Void> markCopyAsLost(@PathVariable String id) {
        markBookLostUseCase.markLost(id);
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/{id}/stock/found")
    public ResponseEntity<Void> restoreLostCopy(@PathVariable String id) {
        restoreLostBookUseCase.restoreLost(id);
        return ResponseEntity.ok().build();
    }

    // --- QUERY ENDPOINTS ---

    @GetMapping("/search-author")
    public ResponseEntity<List<BookSummaryView>> searchByAuthor(@RequestParam String author) {
        return ResponseEntity.ok(findBookByAuthorUseCase.findIgnoreCase(author));
    }

    @GetMapping("/search-genre")
    public ResponseEntity<List<BookSummaryView>> searchByGenre(@RequestParam String genre) {
        return ResponseEntity.ok(findBookByGenreUseCase.findIgnoreCase(genre));
    }

    @GetMapping("/{id}")
    public ResponseEntity<BookDetailView> getBookById(@PathVariable String id) {
        BookDetailView book = findBookByIdUseCase.find(id);
        return ResponseEntity.ok(book);
    }

    @GetMapping("/isbn/{isbn}")
    public ResponseEntity<BookDetailView> getBookByIsbn(@PathVariable String isbn) {
        return findBookByIsbnUseCase.find(isbn)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/search-title")
    public ResponseEntity<List<BookSummaryView>> searchByTitle(@RequestParam String title) {
        return ResponseEntity.ok(findBookByTitleUseCase.find(title));
    }

    @GetMapping("/search-lowstock")
    public ResponseEntity<List<BookSummaryView>> searchByLowStock(
            @RequestParam(defaultValue = "3") long threshold) {
        return ResponseEntity.ok(findLowStockBookUseCase.findLowOnStock(threshold));
    }

    @GetMapping
    public ResponseEntity<List<BookSummaryView>> getAllBooks() {
        return ResponseEntity.ok(getAllBooksUseCase.find());
    }

    @PostMapping("/predict-genre")
    public ResponseEntity<GenrePredictionResponse> predictGenre(
            @RequestBody GenrePredictionRequest request) {
        return ResponseEntity.ok(predictGenreUseCase.predict(request.title(), request.description()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<BookDetailView> updateBook(@PathVariable String id, @RequestBody UpdateBookCommand command) {
        return ResponseEntity.ok(updateBookUseCase.update(id, command));
    }

    @GetMapping("/{bookId}/available")
    public ResponseEntity<Boolean> checkAvailability(@PathVariable String bookId) {
        try {
            BookDetailView book = findBookByIdUseCase.find(bookId);
            boolean available = book.availableStock() != null && book.availableStock() > 0;
            return ResponseEntity.ok(available);
        } catch (Exception e) {
            return ResponseEntity.ok(false);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBook(@PathVariable String id) {
        deleteBookUseCase.deleteBook(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/batch-titles")
    public ResponseEntity<Map<String, String>> getBatchTitles(@RequestParam("ids") Set<String> ids) {
        Map<String, String> titles = getBookTitlesBatchUseCase.getTitles(ids);
        return ResponseEntity.ok(titles);
    }

    @GetMapping("/archived")
    public ResponseEntity<List<BookSummaryView>> getArchivedBooks() {
        return ResponseEntity.ok(getArchivedBooksUseCase.getArchived());
    }

    @PatchMapping("/{id}/restore")
    public ResponseEntity<Void> restoreBook(@PathVariable String id) {
        restoreBookUseCase.restore(id);
        return ResponseEntity.ok().build();
    }
}