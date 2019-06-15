[TOC]

# RESTful example

RESTful api with flask.

## flask-uwsgi-nginx-supervisord

flask app

```python
# api.py
from flask import Flask
from flask_restful import reqparse, abort, Api, Resource

app = Flask(__name__)
api = Api(app)

TODOS = {
    'todo1': {'task': 'build an API'},
    'todo2': {'task': '?????'},
    'todo3': {'task': 'profit!'},
}

def abort_if_todo_doesnt_exist(todo_id):
    if todo_id not in TODOS:
        abort(404, message="Todo {} doesn't exist".format(todo_id))

parser = reqparse.RequestParser()
parser.add_argument('task')


# Todo
# shows a single todo item and lets you delete a todo item
class Todo(Resource):
    def get(self, todo_id):
        abort_if_todo_doesnt_exist(todo_id)
        return TODOS[todo_id]

    def delete(self, todo_id):
        abort_if_todo_doesnt_exist(todo_id)
        del TODOS[todo_id]
        return '', 204

    def put(self, todo_id):
        args = parser.parse_args()
        task = {'task': args['task']}
        TODOS[todo_id] = task
        return task, 201


# TodoList
# shows a list of all todos, and lets you POST to add new tasks
class TodoList(Resource):
    def get(self):
        return TODOS

    def post(self):
        args = parser.parse_args()
        todo_id = int(max(TODOS.keys()).lstrip('todo')) + 1
        todo_id = 'todo%i' % todo_id
        TODOS[todo_id] = {'task': args['task']}
        return TODOS[todo_id], 201

##
## Actually setup the Api resource routing here
##
api.add_resource(TodoList, '/todos')
api.add_resource(Todo, '/todos/<todo_id>')


if __name__ == '__main__':
    app.run(debug=True)

```

run with uwsgi

```bash
$ uwsgi --http :5000 --wsgi-file api.py --callable app --process 3 --threads 2 
*** Starting uWSGI 2.0.18 (64bit) on [Thu Jun 13 16:19:35 2019] ***
compiled with version: 7.4.0 on 12 June 2019 13:38:18
os: Linux-4.15.0-51-generic #55-Ubuntu SMP Wed May 15 14:27:21 UTC 2019
nodename: muto-Desktop
machine: x86_64
clock source: unix
detected number of CPU cores: 4
current working directory: /home/muto/School/supervisord-learning/code/flask-restful/app
detected binary path: /home/muto/.pyenv/versions/3.6.7/envs/env-restful/bin/uwsgi
!!! no internal routing support, rebuild with pcre support !!!
*** WARNING: you are running uWSGI without its master process manager ***
your processes number limit is 31385
your memory page size is 4096 bytes
detected max file descriptor number: 1024
lock engine: pthread robust mutexes
thunder lock: disabled (you can enable it with --thunder-lock)
uWSGI http bound on :5000 fd 4
spawned uWSGI http 1 (pid: 24767)
uwsgi socket 0 bound to TCP address 127.0.0.1:37063 (port auto-assigned) fd 3
Python version: 3.6.7 (default, Jun 12 2019, 13:30:44)  [GCC 7.4.0]
Python main interpreter initialized at 0x5608ee16ac20
python threads support enabled
your server socket listen backlog is limited to 100 connections
your mercy for graceful operations on workers is 60 seconds
mapped 250128 bytes (244 KB) for 6 cores
*** Operational MODE: preforking+threaded ***
WSGI app 0 (mountpoint='') ready in 0 seconds on interpreter 0x5608ee16ac20 pid: 24728 (default app)
*** uWSGI is running in multiple interpreter mode ***
spawned uWSGI worker 1 (pid: 24728, cores: 2)
spawned uWSGI worker 2 (pid: 24769, cores: 2)
spawned uWSGI worker 3 (pid: 24770, cores: 2)
[pid: 24770|app: 0|req: 1/1] 127.0.0.1 () {40 vars in 840 bytes} [Thu Jun 13 16:19:39 2019] GET /todos => generated 94 bytes in 2 msecs (HTTP/1.1 200) 2 headers in 71 bytes (1 switches on core 0)
```

经验证 flask app 是ok的，使用配置文件启动

```ini
# uwsgi.ini
[uwsgi]
socket = :5000
# chown-socket = www-data:www-data
chdir = ./app
processes = 2
threads = 2
stats = 127.0.0.1:9191
module = api
callable = app

```

```bash
$ uwsgi --ini uwsgi.ini

```

配置nginx

```nginx
# /etc/nginx/sites-available/default
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	server_name _;
    
    # http://flask.pocoo.org/docs/1.0/deploying/uwsgi/#configuring-nginx
    location / {
        try_files $uri @app;
    }
    location @app {
        include uwsgi_params;
        # uwsgi_pass unix:///tmp/uwsgi.sock;
        uwsgi_pass 127.0.0.1:5000;
    }
    location /static {
        alias /app/static;
    }
}

```

将uwsgi和nginx配合起来

```bash
$ uwsgi --ini uwsgi.ini &
$ nginx -s reload
$ curl localhost/todos
{"todo1": {"task": "build an API"}, "todo2": {"task": "?????"}, "todo3": {"task": "profit!"}}
$ curl localhost:5000/todos
curl: (52) Empty reply from server
# 由于uwsgi.ini 中将http改为了socket，所以直接访问:5000失效了

```

配置supervisord

```ini
# supervisord.conf
[supervisord]
nodaemon=true

[program:uwsgi]
command=/usr/bin/env uwsgi --ini /app/uwsgi.ini
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:nginx]
# run nginx with daemon off
command=/usr/bin/env nginx -g 'daemon off;'
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
# Graceful stop, see http://nginx.org/en/docs/control.html
stopsignal=QUIT

```

```bash
$ make all
$ $ curl localhost:8888/todos
{"todo1": {"task": "build an API"}, "todo2": {"task": "?????"}, "todo3": {"task": "profit!"}}

```



## NOTE

注意uwsgi --http --socket --http-socket的区别

https://uwsgi-docs.readthedocs.io/en/latest/ThingsToKnow.html



## Useful links

[flask quickstart](http://flask.pocoo.org/docs/1.0/quickstart/#deploying-to-a-web-server)

[flask_restful](https://flask-restful.readthedocs.io/en/latest/)

[uWSGI quickstart](https://uwsgi-docs.readthedocs.io/en/latest/WSGIquickstart.html)

[uWSGI best practice](https://uwsgi-docs.readthedocs.io/en/latest/ThingsToKnow.html)

[supervisord](http://supervisord.org/index.html)

[supervisord configure](http://supervisord.org/configuration.html)

[supervisord faq](http://supervisord.org/faq.html)

[Dockerfile](https://docs.docker.com/engine/reference/builder/)

http://wiki.jikexueyuan.com/project/docker-technology-and-combat/supervisor.html