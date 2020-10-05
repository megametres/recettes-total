FROM rustembedded/cross:arm-unknown-linux-gnueabihf

COPY openssl.sh .
RUN bash /openssl.sh linux-armv4 arm-linux-gnueabihf
ENV OPENSSL_DIR=/openssl \
  OPENSSL_INCLUDE_DIR=/openssl/include \
  OPENSSL_LIB_DIR=/openssl/lib

COPY postgres.sh .
RUN bash /postgres.sh arm-linux arm-linux-gnueabihf

RUN apt-get update && apt-get install -y docker.io

ARG POSTGRES=false
RUN if [ "$POSTGRES" = "true" ] ; then RUN apt-get install -y libpq5 libpq-dev; fi

## Clean up
RUN apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*
