FROM node:20-alpine
WORKDIR /app
COPY product-catalog-middleware/package*.json ./
RUN npm ci
COPY product-catalog-middleware/ ./
ARG EXPOSE_PORT_HTTP
EXPOSE $EXPOSE_PORT_HTTP
ARG EXPOSE_PORT_HTTPS
EXPOSE $EXPOSE_PORT_HTTPS
CMD ["node", "index.js"]
