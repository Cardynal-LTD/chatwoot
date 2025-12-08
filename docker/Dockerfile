# ============================================================================
# DOCKERFILE POUR CHATWOOT - BUILD COMPLET DEPUIS UN FORK
# ============================================================================
# Ce Dockerfile reproduit exactement le pipeline officiel Chatwoot
# Testé et fonctionnel pour la version 4.x avec Vite + pnpm
# ============================================================================

# ============================================================================
# STAGE 1: PRE-BUILDER - Installation des dépendances et build des assets
# ============================================================================
FROM ruby:3.4.4-alpine3.21 AS pre-builder

# Arguments de build
ARG RAILS_ENV=production
ARG NODE_VERSION="23.7.0"
ARG PNPM_VERSION="10.2.0"

# Variables d'environnement
ENV RAILS_ENV=${RAILS_ENV}
ENV NODE_ENV=production
ENV BUNDLER_VERSION=2.5.11
ENV NODE_VERSION=${NODE_VERSION}
ENV PNPM_VERSION=${PNPM_VERSION}

# Configuration pnpm
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

WORKDIR /app

# Installation des dépendances système pour Alpine
# Ces packages sont nécessaires pour compiler les gems natives
RUN apk update && apk add --no-cache \
    build-base \
    git \
    curl \
    musl \
    ruby-full \
    ruby-dev \
    gcc \
    make \
    musl-dev \
    openssl \
    openssl-dev \
    g++ \
    linux-headers \
    xz \
    vips \
    vips-dev \
    postgresql-dev \
    libxml2-dev \
    libxslt-dev \
    tzdata \
    bash \
    shared-mime-info

# Installation de Node.js et pnpm via npm (plus fiable sur Alpine)
RUN apk add --no-cache nodejs npm && \
    npm install -g pnpm@${PNPM_VERSION}

# Configuration du gem bundler
RUN gem install bundler:${BUNDLER_VERSION}

# Forcer la compilation native pour Alpine (musl)
# CRITIQUE: Sans ça, grpc et protobuf échouent
RUN bundle config set --local force_ruby_platform true

# Configuration pour ne pas installer les gems de dev/test en production
RUN if [ "$RAILS_ENV" = "production" ]; then \
    bundle config set without 'development test'; \
    fi

# Copier d'abord les fichiers de dépendances pour le cache Docker
COPY Gemfile Gemfile.lock ./
RUN bundle install -j 4 -r 3

# Copier les fichiers de dépendances JS
COPY package.json pnpm-lock.yaml ./

# Installation des dépendances pnpm
# Note: On utilise --frozen-lockfile=false car pnpm peut avoir besoin de résoudre
RUN pnpm install --frozen-lockfile

# Copier tout le code source
COPY . /app

# Créer le répertoire de logs (sinon Rails échoue si RAILS_LOG_TO_STDOUT=false)
RUN mkdir -p /app/log

# ============================================================================
# BUILD DES ASSETS - LA PARTIE CRITIQUE
# ============================================================================
# C'est ici que le build Vite se fait via rake assets:precompile
# SECRET_KEY_BASE est requis même si c'est un placeholder
# ============================================================================
RUN if [ "$RAILS_ENV" = "production" ]; then \
    SECRET_KEY_BASE=precompile_placeholder \
    RAILS_LOG_TO_STDOUT=enabled \
    bundle exec rake assets:precompile \
    && rm -rf spec node_modules tmp/cache; \
    fi

# Générer le fichier .git_sha avec le hash du commit
# Ce fichier est utilisé pour identifier la version déployée
RUN git rev-parse HEAD > /app/.git_sha || echo "unknown" > /app/.git_sha

# Nettoyage pour réduire la taille de l'image
RUN rm -rf /usr/local/bundle/cache/*.gem \
    && find /usr/local/bundle/gems/ \( -name "*.c" -o -name "*.o" \) -delete || true \
    && rm -rf .git .gitignore || true

# ============================================================================
# STAGE 2: FINAL - Image de production légère
# ============================================================================
FROM ruby:3.4.4-alpine3.21

# Arguments et variables d'environnement pour le runtime
ARG RAILS_ENV=production
ARG NODE_VERSION="23.7.0"
ARG PNPM_VERSION="10.2.0"
ARG BUNDLE_WITHOUT="development:test"

ENV RAILS_ENV=${RAILS_ENV}
ENV NODE_ENV=production
ENV BUNDLER_VERSION=2.5.11
ENV BUNDLE_WITHOUT=${BUNDLE_WITHOUT}
ENV NODE_VERSION=${NODE_VERSION}
ENV PNPM_VERSION=${PNPM_VERSION}
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

WORKDIR /app

# Installation des dépendances runtime uniquement (pas de build tools)
RUN apk update && apk add --no-cache \
    libpq \
    libxml2 \
    libxslt \
    vips \
    tzdata \
    bash \
    curl \
    nodejs \
    npm \
    shared-mime-info

# Installer pnpm via npm (pas besoin de corepack sur Alpine)
RUN npm install -g pnpm@${PNPM_VERSION}

# Copier les gems depuis le stage de build
COPY --from=pre-builder /usr/local/bundle /usr/local/bundle

# Copier l'application avec les assets compilés
COPY --from=pre-builder /app /app

# Créer l'utilisateur non-root pour la sécurité
RUN addgroup -g 1000 chatwoot && \
    adduser -u 1000 -G chatwoot -s /bin/sh -D chatwoot && \
    chown -R chatwoot:chatwoot /app

USER chatwoot

# Exposer le port Rails
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Commande par défaut - peut être override dans docker-compose
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
