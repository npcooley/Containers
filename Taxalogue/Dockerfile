# ---------------------------------------------------------------------------
# Dockerfile for taxalogue
#
# IMPORTANT: this must be built for linux/amd64, matching both this repo's
# Gemfile.lock ("PLATFORMS: x86_64-linux") and the target HPC cluster's
# architecture. The --platform flag below is required even on an amd64
# machine (it's a no-op there) and essential on Apple Silicon or other ARM64
# build hosts, where Docker would otherwise default to building an ARM64
# image that silently fails at runtime (missing native .so files bundled
# only for x86_64).
#
# Build on a machine with Docker (does NOT need to be the cluster):
#   docker build --platform linux/amd64 -t taxalogue:1.1.0 .
#
# Then either:
#   (a) push to a registry (Docker Hub, GHCR, quay.io) and pull with Apptainer
#       on the cluster:
#         apptainer pull taxalogue.sif docker://<your-registry>/taxalogue:1.1.0
#   (b) or convert directly to a .sif locally and copy the file over:
#         apptainer build taxalogue.sif docker-daemon://taxalogue:1.1.0
#         scp taxalogue.sif cluster:/path/to/software/
# ---------------------------------------------------------------------------

FROM --platform=linux/amd64 ruby:3.1-bookworm

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

# Patch: wire up taxalogue's own existing 'automatic' bypass for ambiguous
# or homonymous taxon name resolution, which the CLI entry points never
# expose. Without this, an ambiguous match (e.g. the same name present in
# both NCBI and GBIF backbone imports) or a zero-match query blocks forever
# on an interactive Y/n or numbered-choice prompt via Ruby's `gets` - which
# cannot work in a non-interactive SLURM job, and cannot be worked around
# by piping stdin either: this codebase's bare `gets` reads ARGV entries as
# filenames whenever ARGV is non-empty (this is why the earlier crash log
# showed "cannot open --taxon" - Ruby tried to open a file by that name),
# not actual stdin, so a piped answer is silently ignored regardless.
#
# `TaxonHelper.get_taxon_record(..., automatic: true)` is not new or
# untested: .lib/jobs/multiple_jobs.rb and .lib/jobs/bold_job.rb already
# call it exactly this way internally. This patch just extends the same
# behavior to the two call sites that still default to interactive:
# taxalogue.rb's startup taxon resolution (line ~29) and
# TaxonHelper.assign_taxon_info_to_params (used for the general --taxon
# option, taxon_helper.rb line ~297).
#
# TRADEOFF: with automatic: true, a genuinely ambiguous match silently
# picks the first available-rank candidate instead of prompting, rather
# than surfacing the ambiguity to you. A zero-match query still fails
# cleanly with "Cannot find Taxon..." rather than hanging.
#
# Each sed is followed by a grep -q check so the build FAILS LOUDLY if the
# expected source line isn't found exactly as written (e.g. because a
# future taxalogue release changes this code), rather than silently
# leaving the interactive prompt in place unpatched.
RUN sed -i \
      "s/taxon_object = TaxonHelper.get_taxon_record(params)/taxon_object = TaxonHelper.get_taxon_record(params, automatic: true)/" \
      taxalogue.rb \
    && grep -q "TaxonHelper.get_taxon_record(params, automatic: true)" taxalogue.rb
RUN sed -i \
      "s/taxon_object = TaxonHelper.get_taxon_record(params, taxon_name)/taxon_object = TaxonHelper.get_taxon_record(params, taxon_name, automatic: true)/" \
      .lib/helpers/taxon_helper.rb \
    && grep -q "TaxonHelper.get_taxon_record(params, taxon_name, automatic: true)" .lib/helpers/taxon_helper.rb

# Pin Bundler to the exact version the committed Gemfile.lock was generated
# with (see its "BUNDLED WITH" line). This avoids the "could not find
# bundler" mismatch error some Bundler/Ruby combinations hit, without
# resorting to `bundle lock --update`, which would silently re-resolve every
# gem to newer versions the taxalogue maintainer never actually tested.
RUN gem install bundler:2.4.10 --no-document
RUN bundle _2.4.10_ install

# Verify gem dependencies are correctly installed and satisfy the lockfile,
# without executing any taxalogue code. taxalogue.rb itself is NOT invoked
# here (not even with --version): on first run it unconditionally downloads
# and imports NCBI/GBIF taxonomies (~2 hours, multi-GB), which must not
# happen at build time - that data belongs on persistent, bind-mounted
# storage set up at container runtime, not baked into an image layer.
RUN bundle _2.4.10_ check

# Data (downloads/, results/) should be bind-mounted at runtime rather than
# baked into the image - see the SLURM script for how this is wired up.
WORKDIR /opt/taxalogue
ENTRYPOINT ["bundle", "_2.4.10_", "exec", "ruby", "taxalogue.rb"]