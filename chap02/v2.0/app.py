#!/usr/bin/env python3

from flask import Flask, render_template, request
import os,random,socket

app = Flask(__name__)

images = [
    "las-01.jpg",
    "las-02.jpg",
    "las-03.jpg",
    "las-04.jpg",
    "las-05.jpg",
    "las-06.jpg"
]

@app.route('/')
def index():
    host_name = "{} to {}".format(socket.gethostname(), request.remote_addr)

    image_path = "/static/images/" + random.choice(images)

    return render_template('index.html', image_path=image_path, host_name=host_name)

# Main
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 80))
    try:
        app.run(host="0.0.0.0", port=port, debug=True)
    except Exception as ex:
        print(ex)
