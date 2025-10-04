FROM node:20-alpine
WORKDIR /app
COPY product-catalog-middleware/package*.json ./
RUN npm ci
COPY product-catalog-middleware/ ./
ARG EXPOSE_PORT
EXPOSE $EXPOSE_PORT
CMD ["node", "index.js"]
