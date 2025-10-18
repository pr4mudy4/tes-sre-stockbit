# Dockerfile
FROM golang:1.21-alpine AS builder
RUN apk add --no-cache git build-base
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -o /app/main .

FROM alpine:3.18
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/main .
ENV PORT=8080
EXPOSE 8080
USER 1000
CMD ["./main"]

