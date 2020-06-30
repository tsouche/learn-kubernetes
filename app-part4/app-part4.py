from flask import Flask
from redis import Redis, RedisError
import os

# Connect to Redis
# For the argument 'host=xxx': xxx must equal the name of the Redis Master
# Service exactly as it is named in the Kubernetes cluster, failing which the
# Kubernetes DNS will not be able to route the request from this Pod to the
# Redis Master Pod.
redis = Redis(host="redis-master", db=0, socket_connect_timeout=2, socket_timeout=2)

app = Flask(__name__)

@app.route("/version")
def version():
    return "<b>Version 1</b> - <i>bonne année</i>"

@app.route("/")
def hello():
    #capture the variables
    name=os.getenv("NAME", "world")
    host=os.getenv("HOSTNAME")
    try:
        visits = redis.incr("counter")
    except RedisError:
        visits = "<i>cannot connect to Redis, counter disabled</i>"
    # build the html response
    html = "<h3>Hello {name}!</h3><br/>" \
           "<b>Visits:</b>   {visits}<br/>" \
           "<b>Hostname:</b> {hostname} " \
           "<br/>".format(name=name, hostname=host, visits=visits)
    return html

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
