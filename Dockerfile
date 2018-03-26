FROM ubuntu:xenial


#install wget and python
RUN apt-get update && apt-get install -y \
    wget \
    python

#download kolibri
RUN wget -O kolibri-installer.pex https://learningequality.org/r/kolibri-pex-latest


RUN chmod +x kolibri-installer.pex

EXPOSE 8080

CMD ./kolibri-installer.pex start
