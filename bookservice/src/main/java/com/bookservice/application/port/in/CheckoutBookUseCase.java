package com.bookservice.application.port.in;

import com.bookservice.application.dto.BookDetailView;

public interface CheckoutBookUseCase
{
    BookDetailView checkout(String bookid);

}
