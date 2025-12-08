FROM ruby:3.4.4

# --- OS DEPS ---
RUN apt-get update -y && apt-get install -y \
  curl build-essential git \
  postgresql-client \
  imagemagick tzdata \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# --- NODE 23 (requis par Chatwoot) ---
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

# --- PACKAGE MANAGERS JS ---
RUN npm install -g yarn pnpm

WORKDIR /app

# On copie tout (monorepo + workspace pnpm)
COPY . .

ENV RAILS_ENV=production \
    NODE_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

# --- GEMs ---
RUN bundle config set without 'development test' \
  && bundle install --jobs=4 --retry=3

# --- JS DEPS ---
RUN pnpm install

# --- BUILD FRONT COMPLET (pas juste le SDK) ---
RUN pnpm run build

# --- PREP RUNTIME ---
RUN mkdir -p tmp/pids tmp/sockets log

# Port par défaut (Railway override avec $PORT)
ENV PORT=3000
EXPOSE 3000

# --- LANCEMENT SERVEUR ---
# - recrée les dossiers au cas où
# - supprime un éventuel ancien server.pid
# - lance Puma avec la config Chatwoot
CMD ["sh", "-c", "mkdir -p tmp/pids tmp/sockets log && rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb"]
