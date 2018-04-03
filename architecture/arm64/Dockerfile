FROM alpine@sha256:286be1c7f84de7cbae6cf8aa4e13b3ce2f2512353b3e734336e47e92de4a881e

LABEL maintainer="sahil@sahil.xyz"

COPY bin/ /usr/bin/

RUN [ "cross-build-start" ]

#install python
RUN apk update && apk add \
    python

#no need to add cleaning command as alpine cleans package automatically

#download kolibri
RUN wget -O kolibri http://learningequality.org/r/kolibri-pex-latest

#make executable
RUN chmod +x kolibri

#used for storing db and content (used when mounting volume)
RUN mkdir /root/.kolibri

RUN [ "cross-build-end" ]  

EXPOSE 8080

CMD ./kolibri start && tail -f /root/.kolibri/server.log
