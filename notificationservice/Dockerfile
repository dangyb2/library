FROM eclipse-temurin:25-jdk-alpine

# Set the working directory
WORKDIR /app

# Copy the built jar into the container
# (Make sure to run 'mvn clean package' before building the docker image)
COPY target/*.jar app.jar

# Expose the port the app runs on
EXPOSE 8084

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]