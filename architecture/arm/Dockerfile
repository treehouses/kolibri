FROM alpine@sha256:2ed83b97395753366d69f46eb997970baf60fced4cd85932afcfee5ee97d568f

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
