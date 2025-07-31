# stage 1 - Build the JAR(java application runtime) using maven
FROM maven:3.8.3-openjdk-17 AS builder

WORKDIR /app

COPY . .

# create JAR file
RUN mvn clean install -DskipTests=true

# Reexecute the JAR file from the above stage

FROM openjdk:17-alpine

WORKDIR /app

COPY --from=builder /app/target/*.jar /app/target/expenseapp.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/target/expenseapp.jar"]