package com.borrowservice.application.port.out;

import java.util.Map;
import java.util.Set;

public interface BookCatalogPort {

    boolean isBookAvailable(String bookId);

    void addBookStock(String bookId);

    void decreaseBookStock(String bookId);

    void markCopyAsLost(String bookId);

    void restoreLostCopy(String bookId);

    Map<String, String> getBookTitles(Set<String> bookIds);
}