FROM ubuntu:20.04 as spark-base

ENV ENABLE_INIT_DAEMON false
ENV INIT_DAEMON_BASE_URI http://identifier/init-daemon
ENV INIT_DAEMON_STEP spark_master_init

ENV BASE_URL=https://archive.apache.org/dist/spark/
ENV SPARK_VERSION=3.3.0
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/spark
ENV PATH=$PATH:$SPARK_HOME/bin
ENV PYSPARK_SUBMIT_ARGS="--master local[2]"

COPY ./setup_spark/wait-for-step.sh /
COPY ./setup_spark/execute-step.sh /
COPY ./setup_spark/finish-step.sh /

ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update -y \
    # && apt-get install python3 python3-pip wget nano sudo systemctl lsb-core -y \
    && apt-get install curl wget sudo nano openjdk-8-jre python3 python3-pip lsb-core systemctl -y \
    && ln -s /lib64/ld-linux-x86-64.so.2 /lib/ld-linux-x86-64.so.2 \
    && chmod +x *.sh \
    && wget ${BASE_URL}/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && tar -xvzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark \
    && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

WORKDIR /

RUN chmod +x /wait-for-step.sh && chmod +x /execute-step.sh && chmod +x /finish-step.sh

ENV PYTHONHASHSEED 1

# *******************************

FROM spark-base as spark-master

COPY ./setup_spark/master.sh /

ENV SPARK_MASTER_PORT 7077
ENV SPARK_MASTER_WEBUI_PORT 8080
ENV SPARK_MASTER_LOG /spark/logs

EXPOSE 8080 7077 6066

CMD ["/bin/bash", "/master.sh"]

# *******************************

FROM spark-base as spark-worker

COPY ./setup_spark/worker.sh /

# *******************************

FROM spark-base as spark-submit

ENV SPARK_MASTER_NAME spark-master
ENV SPARK_MASTER_PORT 7077

COPY ./setup_spark/submit.sh /

CMD ["/bin/bash", "/submit.sh"]

# *******************************

FROM spark-master as spark-other

RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - 

RUN apt-get update && apt-get install -y postgresql-12

USER postgres
RUN /etc/init.d/postgresql start \
    && psql --command "CREATE DATABASE airflow_db;" \
    && psql --command "CREATE USER airflow WITH PASSWORD 'airflow';" \
    && psql --command "GRANT ALL PRIVILEGES ON DATABASE airflow_db TO airflow;" \
    && psql --command "ALTER USER airflow SET search_path = public;" \
    && psql --command "GRANT ALL ON SCHEMA public TO airflow;"


USER root
WORKDIR /de-env/

RUN mkdir airflow \
    && pip install virtualenv \
    && cd airflow \
    && virtualenv env 

COPY requirements.txt ./requirements.txt

RUN pip install -r requirements.txt

COPY airflow.cfg /root/airflow/airflow.cfg

RUN mkdir /root/airflow/dags

ENV AIRFLOW_HOME=/root/airflow

RUN echo "source /app/airflow_workspace/airflow_env/bin/activate" >> ~/.bashrc

RUN echo "service postgresql start" >> ~/.bashrc

WORKDIR /de-env/airflow


