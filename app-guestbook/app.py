from flask import Flask
import os
import socket
import redis
#from config import redis_uri

# see Redis tutorial at: https://realpython.com/python-redis/#getting-started

# Redis operations on counter:
#   SET at an initial value
#   INCR: increment
#   DECR: decrement

# Redis operations on list:
#   LLEN key                : returns the length of the list stored at key
#   LPUSH key value         : insert the specified value at the head of the list
#                             stored at key
#   LLEN key                : returns the length of the list stored at key
#   LRANGE key beg end      : returns elements from 'beg' to 'end' of the list
#                             stored at key
#   LRANGE key 0 LLEN key   : returns the whole list stored at key
#   LREM key n              : n>0 = removes elements from head to tail
#   LREM key LLEN key       : empty the list


redis_host = "localhost"
redis_port = 6379
redis_password = ""
counter="counter"
msg_list="messages-list"

app = Flask(__name__)

def reset_db():
    # establish the connexion with the Redis datastore
    r = redis.StrictRedis(host=redis_host, port=redis_port,
            password=redis_password, charset="utf-8", decode_responses=True)
    # reset the counter from redis
    r.set(counter,1)
    # delete the message-list
    r.delete(msg-list)

@app.route("/")
def hello():
    # establish the connexion with the Redis datastore
    r = redis.StrictRedis(host=redis_host, port=redis_port, db=0,
            password=redis_password, charset="utf-8", decode_responses=True)
    # increment the counter
    with r.pipeline() as pipe:
        count=pipe.incr(counter)
        number = pipe.llen(msg_list)
        messages = pipe.lrange(msg_list,0,number)
        pipe.execute()
    # build the html header
    name=os.getenv("NAME", "world")
    hostname=socket.gethostname()
    html = "<h3>Hello {name}!</h3> <b>Hostname:</b> {hostname} - <b>Counter:</b> {count}<br/>".format(name,hostname,count)
    html += "<form action = /query method=\"POST\">"
    html += "<label for=\"feedback\">Your feedback:</label>"
    html += "<input type=\"text\" name=\"feedback\" id=\"feedback\" size=\"150\">"
    html += "<input type=\"submit\" name=\"submit\" id=\"submit\">"
    html += "</form>"

    for msg in messages:
        html += "{msg}<br>".format(msg)
    # collect the user's messages
    feedback = "Test user feedback {count}".format(count)
    # write a message onto the REdis datastore
    r.lpush(msg_list, feedback)
    # returns the html message so as to display it
    return html

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
