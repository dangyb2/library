package com.auditservice.application.port.out;

public interface DeadLetterQueuePort {
    int replayMessages();
}