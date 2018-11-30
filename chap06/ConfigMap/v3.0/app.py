from flask import Flask, render_template, request
import os,random,socket,configparser

app = Flask(__name__)

# 環境変数の値取得
project_id = os.environ.get('PROJECT_ID')

# configファイルの読み込み
config = configparser.ConfigParser()
config.read('/etc/config/ui.ini')
 
# configファイルの値の読み込み
color_top = config.get('UI', 'color.top')
text_size = config.getint('UI', 'text.size')

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

    return render_template('index.html', image_path=image_path, proj_id=project_id, host_name=host_name,color_top=color_top,text_size=text_size)

# Main
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 80))
    try:
        app.run(host="0.0.0.0", port=port, debug=True)
    except Exception as ex:
        print(ex)
