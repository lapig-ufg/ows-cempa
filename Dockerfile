FROM registry.lapig.iesa.ufg.br/lapig-images-homol/ows-base:base

# Clone app and npm install on server
ENV URL_TO_APPLICATION_GITHUB="https://github.com/lapig-ufg/ows-cempa.git"
ENV BRANCH="main"

LABEL maintainer="Renato Gomes <renatogomessilverio@gmail.com>"

RUN mkdir -p /APP && cd /APP && git clone -b ${BRANCH} ${URL_TO_APPLICATION_GITHUB} && \
    cd /APP/ows-cempa/src/server && npm install
    
CMD [ "/bin/bash", "-c", "/APP/src/server/prod-start.sh; tail -f /dev/null"]

ENTRYPOINT [ "/APP/Monitora.sh"]
