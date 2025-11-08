FROM node:20-alpine AS build
WORKDIR /app
COPY product-catalog-frontend/package*.json ./
RUN npm ci
COPY product-catalog-frontend/ ./
RUN npm run build

FROM nginx:stable-alpine
COPY --from=build /app/build /usr/share/nginx/html
