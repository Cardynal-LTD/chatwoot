FROM ruby:3.4.4

# --- OS DEPENDENCIES ---
RUN apt-get update -y && apt-get install -y \
  curl build-essential git \
  postgresql-client \
  imagemagick tzdata \
  ca-certificates

# --- NODEJS 23.x ---
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
  && apt-get install -y nodejs

# --- GLOBAL JS PACKAGE MANAGERS ---
RUN npm install -g yarn pnpm

WORKDIR /app

# --- COPY PROJECT ---
COPY . .

ENV RAILS_ENV=production
ENV NODE_ENV=production

# --- RUBY GEMS ---
RUN bundle config set without 'development test' \
  && bundle install

# --- JS DEPENDENCIES ---
RUN pnpm install --frozen-lockfile

# --- BUILD FRONTEND (Chatwoot officiel utilise build:assets) ---
RUN pnpm run build:sdk
# Si tu veux la version normale Chatwoot : pnpm run build:assets

# --- PREP RUNTIME DIRECTORIES ---
RUN mkdir -p tmp/pids tmp/sockets log

ENV PORT=3000
EXPOSE 3000

# ❌ NE SURTOUT PAS FAIRE rake assets:precompile → Chatwoot n’utilise pas Sprockets
# RUN bundle exec rake assets:precompile  <-- supprime cette ligne

# --- SERVER LAUNCH ---
CMD ["sh", "-c", "rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb"]
