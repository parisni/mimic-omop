FROM debian:bookworm
# RPostgres is not packaged in bookworm: it is built from CRAN against libpq-dev.
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates postgresql-client libpq-dev r-base-dev r-cran-dbi wget unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
# install.packages only warns on failure: library() makes the build fail instead.
RUN R -e "install.packages('RPostgres', repos='https://cloud.r-project.org/'); library(RPostgres)"
