# Docker image for the Drone Terraform plugin
#
#     docker build -t jmccann/drone-terraform:latest .
FROM golang:1.12-alpine AS builder

ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

RUN apk add --no-cache git bash make ca-certificates

# Build drone plugin
RUN mkdir -p /tmp/drone-terraform
WORKDIR /tmp/drone-terraform
COPY . .

RUN go mod download
RUN go build -a -tags netgo -o /bin/drone-terraform

# Build terraform
RUN mkdir -p /tmp/git-terraform
WORKDIR /tmp/git-terraform

RUN git clone https://github.com/luis-silva/terraform.git
WORKDIR terraform
RUN git checkout 21680/GCS_OAUTH
RUN make tools
RUN make dev
RUN mv /go/bin/terraform /bin/terraform

# Build terraform provider google
# RUN mkdir -p /tmp/git-terraform-provider-google
# WORKDIR /tmp/git-terraform-provider-google

# RUN git clone https://github.com/luis-silva/terraform-provider-google.git
# WORKDIR terraform-provider-google
# RUN git checkout project_billing
# RUN make build
# RUN mv /go/bin/terraform-provider-google /bin/terraform-provider-google

FROM alpine:3.9

RUN apk -U add ca-certificates
COPY --from=builder /bin/drone-terraform /bin/
COPY --from=builder /bin/terraform /bin/
# COPY --from=builder /bin/terraform-provider-google /bin/

ENTRYPOINT ["/bin/drone-terraform"]
