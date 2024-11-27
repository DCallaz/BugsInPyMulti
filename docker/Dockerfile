FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade

RUN apt-get install -y git curl build-essential wget unzip vim

RUN apt-get install -y python3-all python3-venv python3-pip

RUN apt-get install -y lzma liblzma-dev libbz2-dev libffi-dev \
  libsqlite3-dev libbz2-dev default-libmysqlclient-dev libkrb5-dev \
  zlib1g-dev virtualenv dos2unix

RUN git clone https://github.com/DCallaz/bugsinpy-mf.git

ENV PATH="${PATH}:/bugsinpy-mf/framework/bin"
