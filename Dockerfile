# ── Dockerfile ──

# 1. Base image: a minimal Node 20 install
FROM node:20-slim

# 2. Install all of Playwright’s Linux dependencies in one apt-get step.
#    In particular, note the inclusion of libxkbcommon0 (for libxkbcommon.so.0).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      fonts-liberation \
      libasound2 \
      libatk-bridge2.0-0 \
      libatk1.0-0 \
      libc6 \
      libcairo2 \
      libcurl4 \
      libcups2 \
      libdbus-1-3 \
      libexpat1 \
      libfontconfig1 \
      libgcc1 \
      libglib2.0-0 \
      libgtk-3-0 \
      libnss3 \
      libx11-6 \
      libx11-xcb1 \
      libxcb1 \
      libxcomposite1 \
      libxcursor1 \
      libxdamage1 \
      libxext6 \
      libxfixes3 \
      libxrandr2 \
      libxrender1 \
      libxss1 \
      libxtst6 \
      libxkbcommon0 \
      libgbm1 \
      libpangocairo-1.0-0 \
      libpangocairo-1.0-0 \
      wget \
      xvfb \
      lsb-release \
      fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*

# 3. Create app directory and copy package files
WORKDIR /app
COPY package.json yarn.lock ./

# 4. Install your Node dependencies (including playwright)
RUN yarn install --frozen-lockfile

# 5. Copy the rest of your source code
COPY . .

# 6. (Optional but recommended) Pre-install Playwright browsers & verify dependencies:
#    This downloads Chromium, WebKit, and Firefox at build time, ensuring they’re
#    present in the final image.
RUN npx playwright install --with-deps

# 7. Expose the port your server listens on (adjust if different)
EXPOSE 3000

# 8. Launch command
CMD ["node", "MapFetchServer.js"]
