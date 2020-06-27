from flask import Flask
from redis import Redis, RedisError
import os
import socket

# Connect to Redis
#redis_ip = os.getenv("REDIS_MASTER_SERVICE_HOST")
#redis_port = os.getenv("REDIS_MASTER_SERVICE_PORT")
#redis_server = "{redis_ip}:{redis-port}".format(redis_ip, redis_port)
#redis_server="redis-master"
redis = Redis(host="redis-master", db=0, socket_connect_timeout=2, socket_timeout=2)

app = Flask(__name__)

@app.route("/version")
def version():
    return "<b>Version 1</b> - <i>bonne année</i>"

@app.route("/")
def hello():
    try:
        name=os.getenv("NAME", "world")
    except:
        name="I don't know who to salute..."
    try:
        hostname=os.getenv("HOSTNAME")
    except:
        hostname="I can't find my host name"
    try:
        visits = redis.incr("counter")
    except RedisError:
        visits = "<i>cannot connect to Redis, counter disabled</i>"

    html = "<h3>Hello {name}!</h3><br/><b>Hostname:</b> {hostname} " \
           "<b>Visits:</b>   {visits}<br/>".format(name, hostname, visits)
    return html

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
