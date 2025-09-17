FROM node:18-alpine
WORKDIR /app
COPY product-catalog-middleware/package*.json ./
RUN npm ci
COPY index.js ./
EXPOSE 3000
CMD ["node", "index.js"]
