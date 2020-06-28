from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def hello():
    name=os.getenv("NAME", "world")
    host=os.getenv("HOSTNAME")
    html = "<h3>Hello {name}!</h3> - application version 1 -<br/>" \
           "<b>Hostname:</b> {host}<br/>".format(name=name, host=host)
    return html

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
