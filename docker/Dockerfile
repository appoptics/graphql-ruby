FROM mongo:4.2

FROM ubuntu:16.04

# install OS packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       apt-utils \
       curl \
       git-core \
       gnupg \
       libpcre3-dev \
       libreadline-dev \
       libsasl2-dev \
       libssl-dev \
       openjdk-8-jdk \
       zlib1g-dev \
       libcurl4-gnutls-dev \
       libmysqlclient-dev \
       libpq-dev \
       sqlite3 \
       vim \
       less \
       tcl \
       tree \
       psmisc \
       wget \
    && rm -rf /var/lib/apt/lists/*

# rbenv setup
# use rbenv-default-gems to automatically install bundler for each ruby version
RUN  git clone https://github.com/rbenv/rbenv.git ~/.rbenv \
     && git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build \
     && git clone https://github.com/rbenv/rbenv-default-gems.git ~/.rbenv/plugins/rbenv-default-gems \
     && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.profile \
     && echo 'eval "$(rbenv init -)"' >> ~/.profile \
     && echo 'eval "$(rbenv init -)"' >> ~/.bashrc \
     && echo 'bundler' > ~/.rbenv/default-gems

RUN echo 'alias be="bundle exec"' >> ~/.bashrc
RUN echo 'alias be="bundle exec"' >> ~/.profile

RUN . ~/.profile \
    && cd /root/.rbenv/plugins/ruby-build && git pull && cd - \
    && rbenv install 2.6.4 \
    && rbenv install 2.7.0-preview1

RUN echo 'gem: --no-document' >> ~/.gemrc

ENV PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH"
ENV RUBY_ENV=test

WORKDIR /code/graphql-ruby

CMD /bin/bash