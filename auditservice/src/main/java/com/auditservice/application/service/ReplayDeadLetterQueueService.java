package com.auditservice.application.service;

import com.auditservice.application.port.in.ReplayDeadLetterQueueUseCase;
import com.auditservice.application.port.out.DeadLetterQueuePort;

public class ReplayDeadLetterQueueService implements ReplayDeadLetterQueueUseCase {

    private final DeadLetterQueuePort deadLetterQueuePort;

    public ReplayDeadLetterQueueService(DeadLetterQueuePort deadLetterQueuePort) {
        this.deadLetterQueuePort = deadLetterQueuePort;
    }

    @Override
    public int replay() {
        return deadLetterQueuePort.replayMessages();
    }
}