FROM golang:alpine AS builder

RUN apk add --no-cache git

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o ganesha-backend .

FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata
RUN cp /usr/share/zoneinfo/Asia/Jakarta /etc/localtime && echo "Asia/Jakarta" > /etc/timezone

WORKDIR /app
COPY --from=builder /app/ganesha-backend .

RUN mkdir -p uploads/profiles

EXPOSE 8080

CMD ["./ganesha-backend"]
