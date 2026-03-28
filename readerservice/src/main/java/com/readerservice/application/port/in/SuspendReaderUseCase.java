package com.readerservice.application.port.in;


public interface SuspendReaderUseCase {


    void suspend(String id, String reason);
}
