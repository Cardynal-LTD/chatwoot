FROM ruby:3.4

# Install dependencies
RUN apt-get update -y && apt-get install -y \
  curl build-essential nodejs npm postgresql-client git

# Install yarn and pnpm
RUN npm install -g yarn pnpm

WORKDIR /app
COPY . .

ENV RAILS_ENV=production
ENV NODE_ENV=production

# Install ruby deps
RUN bundle install --without development test

# Install JS deps
RUN pnpm install

# Precompile assets
RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "3000"]
