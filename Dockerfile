FROM baseimage:latest
MAINTAINER muto@cr.net
RUN apt-get update
COPY ./app /app
RUN apt-get install -y nginx
RUN pip3 install setuptools
RUN pip3 install -r /app/requirements.txt
COPY ./supervisord.conf /etc/supervisor/conf.d/
COPY ./default /etc/nginx/sites-available/default
WORKDIR /app
EXPOSE 80
CMD ["/usr/bin/supervisord"]

