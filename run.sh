docker run \
-d \
-p 7979:8080 \ 
-e LOAD_EX=n \
-e AWS_ACCESS_KEY_ID='placeholder' \
-e AWS_SECRET_ACCESS_KEY='placeholder' \
yashk/docker-airflow:latest
