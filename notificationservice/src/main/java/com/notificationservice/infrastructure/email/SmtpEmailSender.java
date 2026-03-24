package com.notificationservice.infrastructure.email;

import com.notificationservice.application.port.out.EmailSender;
import com.notificationservice.domain.exception.NotificationPublishException;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;

@Component
public class SmtpEmailSender implements EmailSender {

    private static final Logger log = LoggerFactory.getLogger(SmtpEmailSender.class);

    private final JavaMailSender mailSender;
    private final String fromAddress;

    public SmtpEmailSender(JavaMailSender mailSender,
                           @Value("${notification.mail.from:${spring.mail.username:no-reply@example.com}}") String fromAddress) {
        this.mailSender = mailSender;
        this.fromAddress = fromAddress;
    }

    @Override
    public void send(String recipientEmail, String subject, String content) {
        try {
            // 1. Create a MimeMessage instead of a SimpleMailMessage
            MimeMessage message = mailSender.createMimeMessage();

            // 2. Use MimeMessageHelper.
            // The 'true' flag indicates multipart (good for HTML), and "UTF-8" ensures Vietnamese characters don't break.
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromAddress);
            helper.setTo(recipientEmail);
            helper.setSubject(subject);

            // 3. THIS IS THE MAGIC FIX: The 'true' parameter tells the mail client it's an HTML email.
            helper.setText(content, true);

            mailSender.send(message);
            log.debug("Successfully dispatched HTML email to {}", recipientEmail);

        } catch (MessagingException e) {
            log.error("Failed to construct or send HTML email to {}", recipientEmail, e);
            // Using your domain exception to keep the architecture clean!
            throw new NotificationPublishException("Failed to dispatch email to " + recipientEmail, e);
        }
    }
}