# syntax = docker/dockerfile:1

# Adjust NODE_VERSION if you want a different Node.js
ARG NODE_VERSION=20.18.0
FROM node:${NODE_VERSION}-slim AS base

LABEL fly_launch_runtime="NodeJS"

WORKDIR /app
ENV NODE_ENV=production

#
# ─── BUILD STAGE ────────────────────────────────────────────────────────────────
#
FROM base AS build

# Install Debian packages that Playwright needs (and build tools for native modules)
RUN apt-get update -qq && \
    apt-get install -y \
      python-is-python3 \
      pkg-config \
      build-essential \
      libnss3 \
      libatk1.0-0 \
      libatk-bridge2.0-0 \
      libx11-xcb1 \
      libxcomposite1 \
      libxcursor1 \
      libxdamage1 \
      libxext6 \
      libxfixes3 \
      libxrandr2 \
      libgbm-dev \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libcups2 \
      libdrm2 \
      libasound2 \
      libxshmfence1 \
      libwayland-client0 \
      libwayland-cursor0 \
      libwayland-egl1 \
      libegl1 \
      libdbus-1-3 \
      libfontconfig1 \
      libfreetype6 \
      libglib2.0-0 \
      libharfbuzz0b \
      libjpeg-dev \
      libpng-dev \
      libxss1 \
      wget \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy package.json + lockfile, install dependencies
COPY --link package.json package-lock.json ./
RUN npm ci

# Install Playwright browsers (with all system dependencies)
RUN npx playwright install --with-deps

# Copy the rest of your application code
COPY --link . .

#
# ─── FINAL IMAGE ────────────────────────────────────────────────────────────────
#
FROM base

# Re-install runtime dependencies so Playwright can run
RUN apt-get update -qq && \
    apt-get install -y \
      libnss3 \
      libatk1.0-0 \
      libatk-bridge2.0-0 \
      libx11-xcb1 \
      libxcomposite1 \
      libxcursor1 \
      libxdamage1 \
      libxext6 \
      libxfixes3 \
      libxrandr2 \
      libgbm-dev \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libcups2 \
      libdrm2 \
      libasound2 \
      libxshmfence1 \
      libwayland-client0 \
      libwayland-cursor0 \
      libwayland-egl1 \
      libegl1 \
      libdbus-1-3 \
      libfontconfig1 \
      libfreetype6 \
      libglib2.0-0 \
      libharfbuzz0b \
      libjpeg-dev \
      libpng-dev \
      libxss1 \
      wget \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy built application (including node_modules and Playwright browsers) from build
COPY --from=build /app /app

WORKDIR /app

# Make sure your package.json has:
#    "scripts": { "start": "node MapFetchServer.js" }
#
CMD ["npm", "run", "start"]
