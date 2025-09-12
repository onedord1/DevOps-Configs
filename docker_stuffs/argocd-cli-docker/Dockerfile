
FROM argoproj/argocd:v2.6.15 AS builder

FROM alpine:latest

COPY --from=builder /usr/local/bin/argocd /usr/local/bin/argocd

