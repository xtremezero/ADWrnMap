# syntax = docker/dockerfile:1

# ─── ARG & BASE IMAGE ──────────────────────────────────────────────────────────
ARG NODE_VERSION=20.18.0
FROM node:${NODE_VERSION}-slim AS base

LABEL fly_launch_runtime="NodeJS"
WORKDIR /app
ENV NODE_ENV=production

# Instruct Playwright to place its browser binaries under /app/.cache/ms-playwright
ENV PLAYWRIGHT_BROWSERS_PATH=/app/.cache/ms-playwright

#
# ─── BUILD STAGE ────────────────────────────────────────────────────────────────
#
FROM base AS build

# Install Debian packages needed for native modules AND Playwright
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
      libxkbcommon0 \          # ← Ensure this is present at build too
      wget \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy package.json + lockfile, install dependencies
COPY --link package.json package-lock.json ./
RUN npm ci

# Download Playwright browsers (they’ll end up under /app/.cache/ms-playwright)
RUN npx playwright install --with-deps

# Copy the rest of the application (including your MapFetchServer.js)
COPY --link . .

#
# ─── FINAL IMAGE ────────────────────────────────────────────────────────────────
#
FROM base

# Re‐install runtime-only libraries so that Chromium can launch at runtime
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
      libxkbcommon0 \          # ← Add this so chromium_headless_shell can load libxkbcommon.so.0
      wget \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy everything (code, node_modules, and the cached browsers) from build
COPY --from=build /app /app

WORKDIR /app

# Ensure the same PLAYWRIGHT_BROWSERS_PATH is set at runtime
ENV PLAYWRIGHT_BROWSERS_PATH=/app/.cache/ms-playwright

# Run your MapFetchServer.js
CMD ["npm", "run", "start"]
