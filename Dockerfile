
FROM ruby:2.4-jessie

RUN apt-get update
RUN apt-get install -y genders

# RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
# RUN apt-get install -y nodejs

# RUN ln -s /usr/bin/nodejs /usr/local/bin/node

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 20 --retry 5

# RUN npm install -g yarn
# COPY package.json elm-package.json yarn.lock ./
# RUN yarn install
# RUN node_modules/elm/binwrappers/elm-package install

ADD . ./

# CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
