# VERSION 1.10.9
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.7-slim-buster
LABEL maintainer="Yashk_"

# Never prompt the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.10.10
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

# Disable noisy "Handling signal" log messages:
# ENV GUNICORN_CMD_ARGS --log-level WARNING

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        wget \
        gnupg \
        zip \
        unzip \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow \
    && pip install -U pip setuptools wheel \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql,ssh${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && pip install 'redis==3.2' \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_USER_HOME}

EXPOSE 8080 5555 8793

USER airflow
RUN curl -s "https://get.sdkman.io" | /bin/bash
RUN /bin/bash -c 'source $HOME/.sdkman/bin/sdkman-init.sh; \
sdk install java 8.0.252.hs-adpt; \
sdk install spark 2.4.6;'

RUN /bin/bash -c 'cp /usr/local/airflow/.sdkman/candidates/spark/current/conf/spark-env.sh.template /usr/local/airflow/.sdkman/candidates/spark/current/conf/spark-env.sh && \
echo JAVA_HOME=/usr/local/airflow/.sdkman/candidates/java/current >> /usr/local/airflow/.sdkman/candidates/spark/current/conf/spark-env.sh'

RUN /bin/bash -c 'mkdir -p $HOME/tmp && \
mkdir -p $HOME/.local/bin/'

RUN /bin/bash -c 'pwd;ls -lrth $HOME/tmp && \
ls -lrth $HOME/.local/bin/'


WORKDIR ${AIRFLOW_USER_HOME}/tmp

RUN /bin/bash -c 'pwd;ls -lrth $HOME/tmp && \
ls -lrth $HOME/.local/bin/'

RUN /bin/bash -c 'wget https://github.com/peak/s5cmd/releases/download/v1.0.0/s5cmd_1.0.0_Linux-64bit.tar.gz && \
tar -xvf s5cmd_1.0.0_Linux-64bit.tar.gz && \
mv s5cmd $HOME/.local/bin/ && \
chmod +x $HOME/.local/bin/s5cmd'


RUN /bin/bash -c 'wget https://github.com/colinmarc/hdfs/releases/download/v2.1.1/gohdfs-v2.1.1-linux-amd64.tar.gz && \
tar -xvf gohdfs-v2.1.1-linux-amd64.tar.gz && \
mv $HOME/tmp/gohdfs-v2.1.1-linux-amd64/hdfs $HOME/.local/bin/ && \
chmod +x $HOME/.local/bin/hdfs'

RUN /bin/bash -c 'rm -rf $HOME/tmp'

RUN /bin/bash -c 'mkdir -p $HOME/hadoop/conf && \
ls -lrth $HOME/hadoop/conf'

RUN /bin/bash -c 'mkdir -p $HOME/data && \
ls -lrth $HOME/data'

RUN /bin/bash -c 'mkdir -p $HOME/dags && \
ls -lrth $HOME/dags'

RUN chown -R airflow: ${AIRFLOW_USER_HOME}

# envs
ENV AWS_ACCESS_KEY_ID="placeholder_access_key_id"
ENV AWS_SECRET_ACCESS_KEY="placeholder_secret_access_key"
ENV HADOOP_HOME="${AIRFLOW_USER_HOME}/hadoop"
# volume -v /var/lib/mesos/spark/spark-2.4.6-bin-hadoop2.7/hdfs:/usr/local/airflow/hadoop/conf
ENV HADOOP_CONF_DIR="${AIRFLOW_USER_HOME}/hadoop/conf"

#airflow env vars
ENV AIRFLOW__CORE__FERNET_KEY="placeholder"
ENV AIRFLOW__CORE__SQL_ALCHEMY_CONN="placeholder"
ENV AIRFLOW_CONN_SPARK_OVH="placeholder"
ENV AIRFLOW_CONN_AWS_OVH="placeholder"
ENV EXECUTOR="placeholder"



WORKDIR ${AIRFLOW_USER_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"]
