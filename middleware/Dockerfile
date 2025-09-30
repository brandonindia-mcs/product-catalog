FROM node:18-alpine
WORKDIR /app
COPY product-catalog-middleware/package*.json ./
RUN npm ci
COPY src/* ./
ARG EXPOSE_PORT
EXPOSE $EXPOSE_PORT
CMD ["node", "index.js"]
