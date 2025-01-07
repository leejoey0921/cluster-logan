# Build mmseqs
ARG APP=mmseqs
FROM debian:bookworm-slim AS builder
RUN apt-get update \
    && apt-get install -y \
      build-essential cmake xxd git wget \
     zlib1g-dev libbz2-dev libatomic1 && \
    rm -rf /var/lib/apt/lists/*;

WORKDIR /opt/build
RUN git clone https://github.com/ChunShow/MMseqs2.git; cd MMseqs2; \
    git checkout -b new_linclust origin/new_linclust; \
    mkdir build; cd build; \
    cmake -DHAVE_AVX2=1 -DHAVE_MPI=0 -DHAVE_TESTS=0 -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF -DCMAKE_EXE_LINKER_FLAGS="-static -static-libgcc -static-libstdc++" \
        -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" -DCMAKE_INSTALL_PREFIX=. ..; \
    make -j $(nproc --all);

# Docker Base: amazon linux 2023
FROM amazonlinux:2023
COPY --from=builder /opt/build/MMseqs2/build/src/${APP} /usr/local/bin/

ARG PROJECT='logan-analysis'
ARG TYPE='runtime'
ARG VERSION='0.0.1'

# Additional Metadata
LABEL container.base.image="amazonlinux:2"
LABEL project.name=${PROJECT}
LABEL project.website="https://gitlab.pasteur.fr/rchikhi_pasteur/logan-analysis"
LABEL container.type=${TYPE}
LABEL container.version=${VERSION}
LABEL container.description="logan-analysis-base image"
LABEL software.license="MIT"
LABEL tags="logan"

# Update Core
RUN yum -y update
RUN yum -y install bash wget time unzip zstd \
           which sudo jq tar bzip2 grep git
RUN python3 -m ensurepip

# AWS S3
ENV PIP_ROOT_USER_ACTION=ignore
RUN pip3 install boto3
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
    unzip awscliv2.zip &&\
    ./aws/install


# Copy Scripts
COPY logan-cluster.sh /

# (for local testing ; will be already mounted in Batch production)
RUN mkdir -p /localdisk

# Increase the default chunksize for `aws s3 cp`.  By default it is 8MB,
# which results in a very high number of PUT and POST requests.  These
# numbers have NOT been experimented on, but chosen to be just below the
# max size for a single-part upload (5GB).  I haven't pushed it higher
# because I don't want to test the edge cases where a filesize is around
# the part limit.
# Configure AWS Locally
RUN chmod 755 logan-cluster.sh  \
 && aws configure set default.region us-east-1 \
 && aws configure set default.s3.multipart_threshold 4GB \
 && aws configure set default.s3.multipart_chunksize 4GB
#==========================================================
# ENTRYPOINT ==============================================
#==========================================================
ENTRYPOINT ["./logan-cluster.sh"]
