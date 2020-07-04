docker exec --user airflow -ti $(docker ps | grep 'yashk/docker-airflow:latest'|awk '{print $NF}')  /bin/bash
