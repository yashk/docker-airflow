docker ps | grep 'yashk/docker-airflow:latest' | awk '{print $1}' | xargs -I{} -n1 docker kill "{}"
