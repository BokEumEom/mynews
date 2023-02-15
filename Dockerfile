# syntax = docker/dockerfile:1-experimental
FROM node:18-alpine AS web-build

WORKDIR /root
COPY web/ ./

RUN npm install
RUN npm run build

FROM golang:1.17-alpine AS go-build

RUN apk add build-base
RUN go install github.com/gocopper/cli/cmd/copper@v1.2.2

WORKDIR /root

COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download

COPY . .
COPY --from=web-build /root/build ./web/build/.

RUN --mount=type=cache,target=/root/.cache/go-build copper build

FROM alpine:3.16

WORKDIR /root

COPY config/ config/

COPY --from=go-build /root/build/migrate.out .
RUN ["./migrate.out", "--config", "config/prod.toml"]

COPY --from=go-build /root/build/app.out .
CMD ["./app.out", "--config", "config/prod.toml"]