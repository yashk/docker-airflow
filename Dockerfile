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
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        llvm \
        libncurses5-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libffi-dev \
        liblzma-dev \
        python-openssl \
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
        /usr/share/doc-base \
    && /bin/bash -c 'export SDKMAN_DIR="/usr/local/sdkman" && curl -s "https://get.sdkman.io?rcupdate=false" | /bin/bash' \
    && /bin/bash -c 'export SDKMAN_DIR="/usr/local/sdkman" && source /usr/local/sdkman/bin/sdkman-init.sh && \
       sdk install java 8.0.262.hs-adpt && \
       sdk install spark 2.4.6' \
    && /bin/bash -c 'cp /usr/local/sdkman/candidates/spark/current/conf/spark-env.sh.template /usr/local/sdkman/candidates/spark/current/conf/spark-env.sh && \
       echo JAVA_HOME=/usr/local/sdkman/candidates/java/current >> /usr/local/sdkman/candidates/spark/current/conf/spark-env.sh' \
    && /bin/bash -c 'wget https://github.com/peak/s5cmd/releases/download/v1.0.0/s5cmd_1.0.0_Linux-64bit.tar.gz && \
       tar -xvf s5cmd_1.0.0_Linux-64bit.tar.gz && \
       mv s5cmd /usr/local/bin/ && \
       rm -rf s5cmd_1.0.0_Linux-64bit.tar.gz CHANGELOG.md LICENSE README.md\
       chmod +x /usr/local/bin/s5cmd' \
    && /bin/bash -c 'wget https://github.com/colinmarc/hdfs/releases/download/v2.1.1/gohdfs-v2.1.1-linux-amd64.tar.gz && \
       tar -xvf gohdfs-v2.1.1-linux-amd64.tar.gz && \
       mv gohdfs-v2.1.1-linux-amd64/hdfs /usr/local/bin/ && \
       rm -rf  gohdfs-v2.1.1-linux-amd64.tar.gz gohdfs-v2.1.1-linux-amd64 && \
       chmod +x /usr/local/bin/hdfs' \
    && /bin/bash -c 'mkdir -p ${AIRFLOW_USER_HOME}/hadoop/conf && \
           ls -lrth ${AIRFLOW_USER_HOME}/hadoop/conf' \
    && /bin/bash -c 'wget http://archive.apache.org/dist/hadoop/core/hadoop-2.7.3/hadoop-2.7.3.tar.gz && \
       tar -xvzf hadoop-2.7.3.tar.gz && \
       mv hadoop-2.7.3 hadoop && \
       mv hadoop /usr/local/ && \
       ls -lrth /usr/local/hadoop && \
       echo "export JAVA_HOME=/usr/local/sdkman/candidates/java/current" > ${AIRFLOW_USER_HOME}/hadoop/conf/hadoop-env.sh' \
    && /bin/bash -c 'mkdir -p ${AIRFLOW_USER_HOME}/data && \
       ls -lrth ${AIRFLOW_USER_HOME}/data' \
    && /bin/bash -c 'mkdir -p ${AIRFLOW_USER_HOME}/dags && \
       ls -lrth ${AIRFLOW_USER_HOME}/dags'

RUN set -ex \
     && /bin/bash -c 'git version; /usr/bin/git version;command -v git' \
     && /bin/bash -c 'export PYENV_ROOT="/usr/local/pyenv" && curl https://pyenv.run | /bin/bash' \
     && /bin/bash -c 'export PATH="/usr/local/pyenv/bin:$PATH" && pyenv install 3.6.8' \
     && /bin/bash -c '{ \
                        echo boto3; \
                        echo matplotlib==3.2.1; \
                        echo flask; \
                        echo pyarrow==0.14.0; \
                        echo numpy==1.15.0; \
                        echo tabulate; \
                        echo tldextract; \
                        echo pytest; \
                        echo pandas==0.25.3; \
                        echo pyyaml; \
                        echo python-dateutil; \
                        echo requests; \
                        echo seaborn; } > requirements.txt' \
     && '/usr/local/pyenv/versions/3.6.8/bin/pip3.6 install -r requirements.txt'

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg
RUN chown -R airflow: ${AIRFLOW_USER_HOME}

EXPOSE 8080 5555 8793

USER airflow

# envs
# to access s3
ENV AWS_ACCESS_KEY_ID="placeholder_access_key_id"
ENV AWS_SECRET_ACCESS_KEY="placeholder_secret_access_key"

# java
ENV JAVA_HOME="/usr/local/sdkman/candidates/java/current"

# to access hdfs
ENV HADOOP_HOME="${AIRFLOW_USER_HOME}/hadoop"
ENV HADOOP_CONF_DIR="${AIRFLOW_USER_HOME}/hadoop/conf"

#to enable pyspark
ENV PYSPARK_PYTHON="/usr/local/pyenv/versions/3.6.8/bin/python3.6"
ENV PYSPARK_DRIVER_PYTHON="/usr/local/pyenv/versions/3.6.8/bin/python3.6"

# spark local ip is required if starting jobs in client mode
ENV SPARK_LOCAL_IP="<placeholder>"


#airflow env vars
ENV AIRFLOW__CORE__FERNET_KEY="placeholder"
ENV AIRFLOW__CORE__SQL_ALCHEMY_CONN="placeholder"
ENV AIRFLOW_CONN_SPARK_OVH="placeholder"
ENV AIRFLOW_CONN_AWS_OVH="placeholder"
ENV EXECUTOR="placeholder"


WORKDIR ${AIRFLOW_USER_HOME}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["webserver"]
