FROM alpine as py-ea
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
RUN apk update && \
    apk upgrade && \
    apk add ca-certificates openssl-dev openssl libffi-dev python2 python2-dev py2-pip py2-yaml gcc musl-dev tzdata  wget && \
# Download and unpack Elastalert.
    wget -O elastalert.zip "${ELASTALERT_URL}" && \
    unzip elastalert.zip && \
    rm elastalert.zip && \
    mv e* "${ELASTALERT_HOME}"

WORKDIR "${ELASTALERT_HOME}"

# Install Elastalert.
RUN python setup.py install && \
    pip install -e . && \
    pip uninstall twilio --yes && \
    pip install twilio>=6.0.0 && \

FROM node:alpine

# Directory holding configuration for Elastalert and Supervisor.
ENV CONFIG_DIR /opt/config
# Elastalert rules directory.
ENV RULES_DIRECTORY /opt/rules
# Elastalert configuration file path in configuration directory.
ENV ELASTALERT_CONFIG ${CONFIG_DIR}/elastalert_config.yaml
# Directory to which Elastalert and Supervisor logs are written.
ENV LOG_DIR /opt/logs

EXPOSE 3030

RUN apk update && apk upgrade && apk add --no-cache python2 curl \
    mkdir -p "${CONFIG_DIR}" && \
    mkdir -p "${RULES_DIRECTORY}" && \
    mkdir -p "${LOG_DIR}"

# Define mount points.
VOLUME [ "${CONFIG_DIR}", "${RULES_DIRECTORY}", "${LOG_DIR}"]

COPY --from=py-ea /usr/lib/python2.7/site-packages /usr/lib/python2.7/site-packages
COPY --from=py-ea /opt/elastalert /opt/elastalert

WORKDIR /opt/elastalert-server
COPY . /opt/elastalert-server

RUN npm install --production --quiet
COPY config/elastalert.yaml /opt/elastalert/config.yaml
COPY config/config.json config/config.json
COPY elastalert_modules/ /opt/elastalert/elastalert_modules

ENTRYPOINT ["npm", "start"]
