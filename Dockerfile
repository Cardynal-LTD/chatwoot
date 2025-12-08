FROM ruby:3.4.4

# OS dependencies
RUN apt-get update -y && apt-get install -y \
  curl build-essential git \
  postgresql-client \
  nodejs npm \
  imagemagick tzdata

# Install JS package managers
RUN npm install -g yarn pnpm

WORKDIR /app

# Copy your ENTIRE fork (avec ton branding)
COPY . .

ENV RAILS_ENV=production
ENV NODE_ENV=production

# Install Ruby deps
RUN bundle config set without 'development test' \
 && bundle install

# Install JS deps
RUN pnpm install

# Build frontend
RUN pnpm build

EXPOSE 3000

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "3000"]
