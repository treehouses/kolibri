FROM multiarch/alpine:armhf-latest-stable

#install python
RUN apk update && apk add \
    python \
    curl

#no need to add cleaning command as alpine cleans package automatically

#download the latest
RUN curl --silent "https://api.github.com/repos/learningequality/kolibri/releases/latest" \
    | grep "browser_download_url.*pex" \
    | cut -d '"' -f 4 \
    | xargs curl -o kolibri -L

#make executable
RUN chmod +x kolibri

#used for storing db and content (used when mounting volume)
RUN mkdir /root/.kolibri

EXPOSE 8080

CMD ./kolibri start && tail -f /root/.kolibri/logs/kolibri.txt
