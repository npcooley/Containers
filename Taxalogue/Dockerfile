FROM ruby:3.1-bookworm

# build with:
# docker build --platform linux/amd64 -t npcooley/taxalogue:0.0.1 .

# Explicit, pinned version so the image is reproducible even if the taxalogue
# repo changes later.
ARG TAXALOGUE_VERSION=1.1.0

# Fail the build if any step below fails, rather than silently producing a
# broken image.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build tools + vsearch (available as a Debian package on bookworm) +
# wget/tar for fetching the release archive.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nano \
        build-essential \
        wget \
        ca-certificates \
        vsearch \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN wget --no-verbose \
        "https://github.com/nwnoll/taxalogue/archive/refs/tags/v${TAXALOGUE_VERSION}.tar.gz" \
    && tar xzf "v${TAXALOGUE_VERSION}.tar.gz" \
    && rm "v${TAXALOGUE_VERSION}.tar.gz" \
    && mv "taxalogue-${TAXALOGUE_VERSION}" taxalogue

WORKDIR /opt/taxalogue

RUN gem install bundler:2.4.10 --no-document
RUN bundle _2.4.10_ install
 
# Verify gem dependencies are correctly installed and satisfy the lockfile,
# without executing any taxalogue code. taxalogue.rb itself is NOT invoked
# here (not even with --version): on first run it unconditionally downloads
# and imports NCBI/GBIF taxonomies (~2 hours, multi-GB), which must not
# happen at build time - that data belongs on persistent, bind-mounted
# storage set up at container runtime, not baked into an image layer.
RUN bundle _2.4.10_ check
 
# Create an empty placeholder for the SQLite taxonomy database so a bind
# mount has a valid target file to attach to at container runtime. The repo
# ships .db/database.yaml (config) but gitignores the actual database.db
# (data) - see .gitignore - so this file does not exist until this line.
# RUN touch .db/database.db

# Data (downloads/, results/) should be bind-mounted at runtime rather than
# baked into the image - see the SLURM script for how this is wired up.
WORKDIR /opt/taxalogue
ENTRYPOINT ["bundle", "_2.4.10_", "exec", "ruby", "taxalogue.rb"]
