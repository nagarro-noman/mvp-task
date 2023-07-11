from flask import Flask, render_template, request, redirect, url_for, send_from_directory
import os

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER


@app.route("/favicon.ico")
def favicon():
    return send_from_directory(os.path.join(app.root_path, 'static'), 'favicon.ico', mimetype='image/vnd.microsoft.icon')


@app.route('/')
def home():
    return render_template('home.html')


@app.route('/upload', methods=['GET', 'POST'])
def upload():
    if request.method == 'POST':
        file = request.files['file']
        if file:
            filename = file.filename
            # file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
            print(filename)
            return redirect(url_for('results'))
    return render_template('upload.html')


@app.route('/result')
def results():
    # file_list = os.listdir(app.config['UPLOAD_FOLDER'])
    # print(f"result = {file_list}")
    file_list = ["hetst", "afsd"]
    return render_template('results.html', files=file_list)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
