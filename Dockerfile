FROM ruby:3.4.4

# --- SYSTEM DEPENDENCIES ---
RUN apt-get update -y && apt-get install -y \
  curl build-essential git \
  postgresql-client \
  imagemagick tzdata \
  ca-certificates

# --- INSTALL NODE 23 ---
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
  && apt-get install -y nodejs

# --- GLOBAL PACKAGE MANAGERS ---
RUN npm install -g yarn pnpm

WORKDIR /app

# --- COPY PROJECT ---
COPY . .

ENV RAILS_ENV=production
ENV NODE_ENV=production

# --- INSTALL RUBY DEPS ---
RUN bundle config set without 'development test' \
  && bundle install

# --- INSTALL JS DEPS ---
RUN pnpm install

# --- Chatwoot SDK build (optional but recommended) ---
RUN pnpm run build:sdk

# --- FRONTEND + VITE ASSETS (MAIN BUILD) ---
RUN bundle exec rake assets:precompile

# --- PREP RUNTIME FOLDERS ---
RUN mkdir -p tmp/pids tmp/sockets log

ENV PORT=3000
EXPOSE 3000

# --- START SERVER ON RAILWAY ---
CMD ["sh", "-c", "mkdir -p tmp/pids tmp/sockets log && rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb"]
