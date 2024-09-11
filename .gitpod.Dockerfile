# Use the latest stable Debian release
FROM debian:stable-slim

# Update package lists and install essential packages
RUN apt-get update && apt-get install -yq \
    sudo \
    curl \
    g++ \
    gcc \
    autoconf \
    automake \
    bison \
    libc6-dev \
    libffi-dev \
    libgdbm-dev \
    libncurses5-dev \
    libsqlite3-dev \
    libtool \
    libyaml-dev \
    make \
    pkg-config \
    sqlite3 \
    zlib1g-dev \
    libgmp-dev \
    libreadline-dev \
    libssl-dev \
    gnupg2 \
    procps \
    libpq-dev \
    vim \
    git

# Create the 'gitpod' user with appropriate permissions
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod \
    && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

# Set environment variables and working directory
ENV HOME=/home/gitpod
WORKDIR $HOME

# Switch to the 'gitpod' user
USER gitpod

# Install RVM (Ruby Version Manager)
RUN gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s stable

# Install Ruby and set it as the default
RUN echo "rvm_gems_path=/home/gitpod/.rvm" > ~/.rvmrc
RUN bash -lc "rvm install ruby-3.2.2 && rvm use ruby-3.2.2 --default" # Use the latest stable Ruby version
RUN echo "rvm_gems_path=/workspace/.rvm" > ~/.rvmrc
RUN bash -lc "rvm get stable --auto-dotfiles"

# Set environment variables for Ruby
ENV GEM_HOME=/workspace/.rvm

# Install Heroku CLI
RUN curl https://cli-assets.heroku.com/install-ubuntu.sh | sh

# Install PostgreSQL and set it up
RUN sudo apt-get install -yq postgresql postgresql-contrib

# Setup PostgreSQL server for user 'gitpod'
ENV PGDATA="/workspace/.pgsql/data"

USER postgres
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER gitpod WITH SUPERUSER PASSWORD 'gitpod';" &&\
    createdb -O gitpod gitpod

# Adjust PostgreSQL configuration for remote connections
RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/14/main/pg_hba.conf # Adjust for PostgreSQL 14
RUN echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Switch back to the 'gitpod' user
USER gitpod
