FROM node:alpine3.10

WORKDIR /opt

COPY app.js /opt/app.js

RUN cd /opt && \
    npm i -S express

CMD node /opt/app.js


EXPOSE 3000