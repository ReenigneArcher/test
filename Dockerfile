FROM ruby:3.3-bookworm

#ENV PAGES_REPO_NWO="octocat/dummy-repo"

RUN apt-get update -qq && apt-get install -y build-essential

WORKDIR /app

COPY . .

# Install the gems specified in the Gemfile
RUN bundle install

# Expose the port that Jekyll will run on
EXPOSE 4000

# Command to build and serve the Jekyll site
CMD ["bundle", "exec", "jekyll", "serve", "--config", "_config.yml,_config_local.yml"]
