FROM ruby:3.4.4

# --- INSTALL OS DEPS ---
RUN apt-get update -y && apt-get install -y \
  curl build-essential git \
  postgresql-client \
  imagemagick tzdata \
  ca-certificates

# --- INSTALL NODE 23 (Chatwoot l'exige) ---
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

EXPOSE 3000

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "3000"]
