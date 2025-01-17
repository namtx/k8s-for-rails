FROM ruby:2.7.1-slim

ARG BUILD_ENV=production
ARG RUBY_ENV=production
ARG APP_HOME=/k8s_for_rails
ARG SECRET_KEY_BASE=secret_key_base
ARG NODE_ENV=production
ARG ASSET_HOST=http://localhost
# Set environment varaibles required in the initializers in order to precompile the assets.
# Because it initializes the app, so all variables need to exist in the build stage.
ARG MAILER_DEFAULT_HOST=http://localhost
ARG MAILER_DEFAULT_PORT=3000

# Define all the envs here
ENV BUILD_ENV=$BUILD_ENV \
    RACK_ENV=$RUBY_ENV \
    RAILS_ENV=$RUBY_ENV \
    PORT=80 \
    BUNDLE_JOBS=4 \
    BUNDLE_PATH="/bundle" \
    ASSET_HOST=$ASSET_HOST \
    NODE_ENV=$NODE_ENV \
    NODE_SOURCE_VERSION=12 \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LANGUAGE="en_US:en"

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends apt-transport-https curl gnupg net-tools && \
    apt-get install -y --no-install-recommends build-essential libpq-dev && \
    apt-get install -y --no-install-recommends rsync locales chrpath pkg-config libfreetype6 libfontconfig1 git cmake wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Yarn repository
# Add the PPA (personal package archive) maintained by NodeSource
# This will have more up-to-date versions of Node.js than the official Debian repositories
ADD https://dl.yarnpkg.com/debian/pubkey.gpg /tmp/yarn-pubkey.gpg
RUN apt-key add /tmp/yarn-pubkey.gpg && rm /tmp/yarn-pubkey.gpg && \
    echo "deb http://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_"$NODE_SOURCE_VERSION".x | bash - && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends nodejs yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up the Chrome PPA and install Chrome Headless
RUN if [ "$BUILD_ENV" = "test" ]; then \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' >> /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends google-chrome-stable && \
    rm /etc/apt/sources.list.d/google-chrome.list && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* ; \
    fi

WORKDIR $APP_HOME

# Skip installing gem documentation
RUN mkdir -p /usr/local/etc \
    && { \
    echo '---'; \
    echo ':update_sources: true'; \
    echo ':benchmark: false'; \
    echo ':backtrace: true'; \
    echo ':verbose: true'; \
    echo 'gem: --no-ri --no-rdoc'; \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
    } >> /usr/local/etc/gemrc

# Copy all denpendencies from app and engines into tmp/docker to install
COPY tmp/docker ./

# Install Ruby gems
RUN gem install bundler && \
    bundle config set jobs $BUNDLE_JOBS && \
    bundle config set path $BUNDLE_PATH && \
    if [ "$BUILD_ENV" = "production" ]; then \
    bundle config set deployment yes && \
    bundle config set without 'development test' ; \
    fi && \
    bundle install

# Install JS dependencies
COPY package.json yarn.lock ./
RUN yarn install --network-timeout 100000

# Copying the app files must be placed after the dependencies setup
# since the app files always change thus cannot be cached
COPY . ./

# Remove tmp/docker in the final image
RUN rm -rf tmp/docker

# Compile assets
RUN bundle exec rails i18n:js:export && \
    bundle exec rails assets:precompile

EXPOSE $PORT

CMD ./bin/start.sh
