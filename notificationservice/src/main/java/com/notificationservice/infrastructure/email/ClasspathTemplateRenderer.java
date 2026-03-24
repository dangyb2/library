package com.notificationservice.infrastructure.email;

import com.notificationservice.domain.exception.TemplateLoadException;
import com.notificationservice.application.port.out.TemplateRenderer;
import com.notificationservice.application.service.RenderedEmail;
import com.notificationservice.domain.model.NotificationType;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
@Component
public class ClasspathTemplateRenderer implements TemplateRenderer {
    private final TemplateRegistry registry;

    public ClasspathTemplateRenderer(TemplateRegistry registry) {
        this.registry = registry;
    }

    @Override
    public RenderedEmail render(NotificationType type, Map<String, Object> variables) {
        TemplateDefinition definition = registry.get(type);
        String template = loadTemplate(definition.templateFile());

        Map<String, Object> safeVariables = variables == null ? Map.of() : new HashMap<>(variables);
        String content = applyVariables(template, safeVariables);
        String subject = applyVariables(definition.subject(), safeVariables);

        return new RenderedEmail(subject, content);
    }

    private String loadTemplate(String templateFile) {
        ClassPathResource resource = new ClassPathResource("templates/" + templateFile);
        try {
            return resource.getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException ex) {
            throw new TemplateLoadException(templateFile, ex);
        }
    }

    private String applyVariables(String template, Map<String, Object> variables) {
        if (template == null || variables == null) return template;

        // 1. Define the pattern for {{key}}
        Pattern pattern = Pattern.compile("\\{\\{(.+?)\\}\\}");
        Matcher matcher = pattern.matcher(template);

        // 2. Use StringBuilder as a mutable buffer
        StringBuilder sb = new StringBuilder();

        // 3. Scan the string once
        while (matcher.find()) {
            String key = matcher.group(1); // Extract 'key' from '{{key}}'

            if (variables.containsKey(key)) {
                Object val = variables.get(key);
                String replacement = (val == null) ? "" : val.toString();

                // 4. Matcher handles the heavy lifting of appending
                // the text before the match + the replacement
                matcher.appendReplacement(sb, Matcher.quoteReplacement(replacement));
            } else {
                // If variable isn't in the map, keep the original {{key}}
                matcher.appendReplacement(sb, Matcher.quoteReplacement(matcher.group(0)));
            }
        }

        // 5. Append the remaining part of the string after the last match
        matcher.appendTail(sb);

        return sb.toString();
    }
}
