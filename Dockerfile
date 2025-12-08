FROM ruby:3.4.4

# --- INSTALL OS DEPS ---
RUN apt-get update -y && apt-get install -y \
  curl build-essential git \
  postgresql-client \
  imagemagick tzdata \
  ca-certificates

# --- INSTALL NODE (version récente) ---
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
  && apt-get install -y nodejs

# --- INSTALL PACKAGE MANAGERS ---
RUN npm install -g yarn pnpm

WORKDIR /app

# --- COPY FULL PROJECT (including your branding) ---
COPY . .

ENV RAILS_ENV=production
ENV NODE_ENV=production

# --- INSTALL RUBY DEPENDENCIES ---
RUN bundle config set without 'development test' \
  && bundle install

# --- INSTALL JS DEPENDENCIES ---
RUN pnpm install

# --- BUILD FRONTEND (REAL Chatwoot build command) ---
RUN pnpm run build:sdk

# --- PRÉPARATION DES DOSSIERS RUNTIME ---
RUN mkdir -p tmp/pids tmp/sockets log

# Railway fournit $PORT → on garde 3000 par défaut si absent
ENV PORT=3000
EXPOSE 3000

# --- LANCEMENT SERVEUR (PUMA + PORT RAILWAY + FIX server.pid) ---
CMD ["sh", "-c", "mkdir -p tmp/pids tmp/sockets log && rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb"]
