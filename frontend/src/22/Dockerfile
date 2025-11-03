# Stage 1: Build
FROM node:22-alpine AS build
WORKDIR /app
# Inject environment variable to disable minification
ARG NODE_ENV=development
ENV NODE_ENV=$NODE_ENV
COPY algorithmic-hue/web/package*.json ./
RUN npm ci
COPY algorithmic-hue/web/ .
RUN npm run build -- --mode $NODE_ENV

# Stage 2: Serve only the built app
FROM node:22-alpine
WORKDIR /app
RUN npm install -g serve
COPY --from=build /app/dist ./dist
ARG 2999
EXPOSE $EXPOSE_PORT
CMD ["serve", "-s", "dist", "-l", "$EXPOSE_PORT"]
