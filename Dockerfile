FROM debian
COPY *.sh /
RUN apt-get update ; apt-get install -yqq curl unzip jq bsdmainutils nano
RUN curl -sfL https://raw.githubusercontent.com/akash-network/provider/main/install.sh | bash
RUN cp bin/provider-services /usr/local/bin/akash