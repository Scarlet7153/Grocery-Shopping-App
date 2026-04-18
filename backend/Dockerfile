FROM maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /app

COPY pom.xml ./
COPY .mvn .mvn
COPY mvnw mvnw
RUN chmod +x mvnw

COPY src src

RUN ./mvnw -B -DskipTests clean package \
    && find target -maxdepth 1 -type f -name "*.jar" ! -name "*.jar.original" -exec cp {} app.jar \;

FROM eclipse-temurin:21-jre
WORKDIR /app

COPY --from=builder /app/app.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]