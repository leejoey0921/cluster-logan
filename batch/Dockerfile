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
           which sudo jq tar bzip2 grep git
RUN python3 -m ensurepip

# AWS S3
ENV PIP_ROOT_USER_ACTION=ignore
RUN pip3 install boto3
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
    unzip awscliv2.zip &&\
    ./aws/install

# palmscan
#RUN aws s3 cp s3://serratus-rayan/tools/palmscan2 /usr/local/bin --no-sign-request && chmod +x /usr/local/bin/palmscan2

# gotranseq is buggy, randomly crashes with deadlock
#RUN wget https://github.com/feliixx/gotranseq/releases/download/v0.4.0/gotranseq_0.4.0_Linux_x86_64.tar.gz && \
#    tar xf gotranseq_0.4.0_Linux_x86_64.tar.gz && \
#    rm gotranseq_0.4.0_Linux_x86_64.tar.gz && \
#    mv gotranseq /usr/local/bin/

# transeq
#RUN mkdir /emboss && cd /emboss && aws s3 cp s3://serratus-rayan/tools/emboss-5.0.0-h9f0ad1d_1.tar.bz2 . --no-sign-request && \
#    tar xf emboss-5.0.0-h9f0ad1d_1.tar.bz2
#ENV PATH="$PATH:/emboss/bin"

# s5cmd
RUN wget https://github.com/peak/s5cmd/releases/download/v2.2.2/s5cmd_2.2.2_Linux-64bit.tar.gz &&\
  tar xf s5cmd_2.2.2_Linux-64bit.tar.gz &&\
  rm s5cmd_2.2.2_Linux-64bit.tar.gz &&\
  mv s5cmd  /usr/local/bin

# rclone
#RUN wget https://downloads.rclone.org/v1.66.0/rclone-v1.66.0-linux-amd64.zip && \
# unzip rclone-v1.66.0-linux-amd64.zip && \
# rm rclone-v1.66.0-linux-amd64.zip && \
# mv rclone-v1.66.0-linux-amd64/rclone /usr/local/bin/rclone
#RUN mkdir -p /root/.config/rclone/
#COPY rclone.conf /root/.config/rclone

# Robert's custom 16s search tool
#RUN aws s3 cp s3://serratus-rayan/tools/usearch_16s /usr/local/bin --no-sign-request && chmod +x /usr/local/bin/usearch_16s
#RUN aws s3 cp s3://serratus-rayan/tools/usearch_16s.gg97.bitvec /  --no-sign-request 

# seqtk
RUN aws s3 cp s3://serratus-rayan/tools/seqtk-1.4-he4a0461_2.tar.bz2 . --no-sign-request && \
    tar xf seqtk-1.4-he4a0461_2.tar.bz2 && mv bin/seqtk /usr/local/bin

# circle detection
RUN git clone https://gitlab.pasteur.fr/rchikhi_pasteur/circles-logan.git
RUN pip3 install networkx numpy

# diamond
RUN wget https://github.com/bbuchfink/diamond/releases/download/v2.1.9/diamond-linux64.tar.gz && tar xf diamond-linux64.tar.gz && mv diamond /usr/local/bin

# minimap2
RUN wget https://github.com/lh3/minimap2/releases/download/v2.28/minimap2-2.28_x64-linux.tar.bz2 && tar xf minimap2-2.28_x64-linux.tar.bz2  && mv minimap2-2.28_x64-linux/minimap2 /usr/local/bin

# copy diamond DB
RUN aws s3 cp s3://serratus-rayan/beetles/april26.dmnd . --no-sign-request
RUN aws s3 cp s3://serratus-rayan/beetles/STB.fa . --no-sign-request

# Copy Scripts
COPY logan-analysis.sh /
RUN mkdir /tasks
COPY tasks/* /tasks/

# (for local testing ; will be already mounted in Batch production)
RUN mkdir -p /localdisk

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
