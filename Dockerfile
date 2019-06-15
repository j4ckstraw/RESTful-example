FROM ubuntu:latest
MAINTAINER https://github.com/j4ckstraw
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y wget curl iproute2 git vim
RUN apt-get install -y python3 python3-pip python3-dev build-essential 
RUN apt-get install -y supervisor
COPY ./app /app
RUN apt-get install -y nginx
RUN pip3 install -r /app/requirements.txt
COPY ./supervisord.conf /etc/supervisor/conf.d/
COPY ./default /etc/nginx/sites-available/default
WORKDIR /app
EXPOSE 80
CMD ["/usr/bin/supervisord"]
