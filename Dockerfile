# Étape 1 — Builder les assets frontend
FROM node:20-alpine AS frontend

WORKDIR /app
COPY . .

RUN npm install -g pnpm
RUN pnpm install
RUN pnpm build


# Étape 2 — Builder l’application Rails + copier entrypoints officiels
FROM ruby:3.4.4 AS backend

# Install OS deps
RUN apk add --no-cache \
  build-base \
  postgresql-dev \
  postgresql-client \
  git \
  imagemagick \
  tzdata \
  nodejs \
  yarn

WORKDIR /app

# Copier code
COPY . .

# Installer gems
RUN bundle install --without development test

# Copier assets compilés du frontend
COPY --from=frontend /app/public/packs ./public/packs

# Copier entrypoints Chatwoot (IMPORTANT)
COPY docker/entrypoints /usr/local/bin/chatwoot-entrypoints
RUN chmod +x /usr/local/bin/chatwoot-entrypoints/*.sh

ENV RAILS_ENV=production
ENV NODE_ENV=production

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/chatwoot-entrypoints/rails.sh"]
