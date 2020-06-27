from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def hello():
    name=os.getenv("NAME", "world")
    hostname=os.getenv("HOSTNAME")
    html = "<h3>Hello {name}!</h3> - application version 2 - " \
           "<b>Hostname:</b> {hostname}<br/>".format(name, hostname)
    return html

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
