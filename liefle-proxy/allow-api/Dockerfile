FROM node:20-alpine

RUN apk add --no-cache wget

WORKDIR /app

COPY package.json server.js ./
COPY domains.json /data/domains.json

ENV PORT=8080
ENV HOST=0.0.0.0
ENV DOMAINS_FILE=/data/domains.json

EXPOSE 8080

CMD ["node", "server.js"]
