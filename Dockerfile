# Stage 1: Base con dependencias de producción
FROM node:22.20.0-slim AS base
WORKDIR /usr/src/wpp-server
ENV NODE_ENV=production PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Instalar dependencias del sistema (glibc compatible - funciona con Sharp sin problemas)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libvips42 \
    libvips-dev \
    libfftw3-dev \
    chromium \
    && rm -rf /var/lib/apt/lists/*

# Instalar dependencias de producción
COPY package.json yarn.lock* ./
RUN yarn install --production --pure-lockfile && \
    yarn cache clean

# Stage 2: Build
FROM node:22.20.0-slim AS build
WORKDIR /usr/src/wpp-server
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Instalar dependencias del sistema para build
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libvips-dev \
    libfftw3-dev \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copiar e instalar dependencias
COPY package.json yarn.lock* ./
RUN yarn install --frozen-lockfile

# Copiar código fuente y compilar
COPY . .
RUN yarn build && yarn cache clean

# Stage 3: Production
FROM base
WORKDIR /usr/src/wpp-server/

# Copiar código compilado desde stage build
COPY --from=build /usr/src/wpp-server/dist ./dist
COPY --from=build /usr/src/wpp-server/node_modules ./node_modules
COPY package.json ./

EXPOSE 21465

ENTRYPOINT ["node", "dist/server.js"]
