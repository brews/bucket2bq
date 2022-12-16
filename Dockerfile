FROM golang:1.19

WORKDIR /go/src/github.com/brews/bucket2bq
COPY bucket2bq.avsc .
COPY go.mod .
COPY go.sum .
COPY main.go .

RUN go install -v ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /bucket2bq .

FROM google/cloud-sdk:slim
WORKDIR /
RUN chown -R 1000 /home
COPY --from=0 /bucket2bq .
COPY bigquery.schema .
COPY run.sh .
RUN chmod +x run.sh
CMD ["/run.sh"]
