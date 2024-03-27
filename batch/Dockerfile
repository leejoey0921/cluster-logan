# Docker Base: amazon linux 2023
FROM amazonlinux:2023

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
           which sudo jq 
RUN python3 -m ensurepip

# AWS S3
RUN pip3 install boto3
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
    unzip awscliv2.zip &&\
    ./aws/install

# Copy Scripts
COPY logan-analysis.sh /
RUN mkdir /tasks
COPY tasks/* /tasks/

# Increase the default chunksize for `aws s3 cp`.  By default it is 8MB,
# which results in a very high number of PUT and POST requests.  These
# numbers have NOT been experimented on, but chosen to be just below the
# max size for a single-part upload (5GB).  I haven't pushed it higher
# because I don't want to test the edge cases where a filesize is around
# the part limit.
# Configure AWS Locally
RUN chmod 755 logan-analysis.sh  \
 && aws configure set default.region us-east-1 \
 && aws configure set default.s3.multipart_threshold 4GB \
 && aws configure set default.s3.multipart_chunksize 4GB
#==========================================================
# ENTRYPOINT ==============================================
#==========================================================
ENTRYPOINT ["./logan-analysis.sh"]
