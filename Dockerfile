FROM alpine:latest as py-ea
ARG VERSION
# Set this environment variable to True to set timezone on container start.
ENV SET_CONTAINER_TIMEZONE False
# Default container timezone as found under the directory /usr/share/zoneinfo/.
ENV CONTAINER_TIMEZONE Etc/UTC
# URL from which to download Elastalert.
ENV ELASTALERT_URL https://github.com/Yelp/elastalert/archive/$VERSION.zip
# Elastalert home directory full path.
ENV ELASTALERT_HOME /opt/elastalert

WORKDIR /opt

# Install software required for Elastalert and NTP for time synchronization.
RUN apk update && apk upgrade && \
    apk add ca-certificates openssl-dev openssl python2-dev python2 py2-pip py2-yaml libffi-dev gcc musl-dev wget && \
# Download and unpack Elastalert.
    wget -O elastalert.zip "${ELASTALERT_URL}" && \
    unzip elastalert.zip && \
    rm elastalert.zip && \
    mv e* "${ELASTALERT_HOME}"

WORKDIR "${ELASTALERT_HOME}"

# Install Elastalert.
RUN python setup.py install && \
    pip install -r requirements.txt

FROM alpine:latest

RUN apk update && apk upgrade && apk add --no-cache nodejs nodejs-npm curl tzdata python2

COPY --from=py-ea /usr/lib/python2.7/site-packages /usr/lib/python2.7/site-packages
COPY --from=py-ea /opt/elastalert /opt/elastalert

WORKDIR /opt/elastalert-server
COPY . /opt/elastalert-server

RUN npm install --production --quiet
COPY config/elastalert.yaml /opt/elastalert/config.yaml
COPY config/config.json config/config.json
COPY elastalert_modules/ /opt/elastalert/elastalert_modules

EXPOSE 3030
ENTRYPOINT ["npm", "start"]
