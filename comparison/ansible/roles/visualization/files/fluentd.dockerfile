FROM fluent/fluentd:v1.6-debian-1

USER root
RUN ["gem", "install", "fluent-plugin-elasticsearch", "--no-document", "--version", "3.5.2"]
RUN apt-get update \
  && apt-get --no-install-recommends install -y apt-utils ca-certificates curl
USER fluent
