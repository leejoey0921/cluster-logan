# Build MMseqs2 natively on ARM64
# debian-bullseye instead of bookworm
# this is to use glibc version supported in amazonlinux:2023 (<= 2.34)
FROM debian:bullseye-slim AS builder
RUN apt-get update \
    && apt-get install -y \
      build-essential cmake xxd git wget \
     zlib1g-dev libbz2-dev libatomic1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/build
RUN git clone https://github.com/soedinglab/MMseqs2.git; cd MMseqs2; \
    mkdir build; cd build; \
    cmake -DHAVE_ARM8=1 -DHAVE_MPI=0 -DHAVE_TESTS=0 -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF -DCMAKE_EXE_LINKER_FLAGS="-static -static-libgcc -static-libstdc++" \
        -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" -DCMAKE_INSTALL_PREFIX=. ..; \
    make -j $(nproc --all);

# Base image: Amazon Linux 2023
FROM amazonlinux:2023
COPY --from=builder /opt/build/MMseqs2/build/src/mmseqs /usr/local/bin/

ARG PROJECT='logan-analysis'
ARG TYPE='runtime'
ARG VERSION='0.0.1'

LABEL container.base.image="amazonlinux:2023"
LABEL project.name=${PROJECT}
LABEL project.website="https://gitlab.pasteur.fr/rchikhi_pasteur/logan-analysis"
LABEL container.type=${TYPE}
LABEL container.version=${VERSION}
LABEL container.description="logan-analysis-base image"
LABEL software.license="MIT"
LABEL tags="logan"

# Update and install dependencies
RUN dnf -y update && \
    dnf -y install bash wget time unzip zstd parallel \
    which sudo jq tar bzip2 grep git

RUN python3 -m ensurepip

# AWS S3
ENV PIP_ROOT_USER_ACTION=ignore
RUN pip3 install boto3
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip &&\
    ./aws/install


# Copy Scripts
COPY logan-merge-tsv-human-complete.sh /

# (for local testing ; will be already mounted in Batch production)
RUN mkdir -p /localdisk

# Increase the default chunksize for `aws s3 cp`.  By default it is 8MB,
# which results in a very high number of PUT and POST requests.  These
# numbers have NOT been experimented on, but chosen to be just below the
# max size for a single-part upload (5GB).  I haven't pushed it higher
# because I don't want to test the edge cases where a filesize is around
# the part limit.
# Configure AWS Locally
RUN chmod 755 logan-merge-tsv-human-complete.sh \
 && aws configure set default.region us-east-1 \
 && aws configure set default.s3.multipart_threshold 4GB \
 && aws configure set default.s3.multipart_chunksize 4GB
#==========================================================
# ENTRYPOINT ==============================================
#==========================================================
ENTRYPOINT ["./logan-merge-tsv-human-complete.sh"]
