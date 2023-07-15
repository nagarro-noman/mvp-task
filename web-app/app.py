from flask import Flask, render_template, request, redirect, url_for, send_from_directory
from werkzeug.utils import secure_filename
import os
import boto3
import pymysql

app = Flask(__name__)
UPLOAD_FOLDER = '/tmp'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
os.environ['AWS_DEFAULT_REGION'] = 'ap-south-1'

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
        filename = secure_filename(file.filename)

        if file:
            # Save the file locally
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
            file.save(file_path)
            
            # Upload the file to S3
            bucket_name = 'nagp-task-bucket-3163353'
            s3 = boto3.client('s3')
            s3.upload_file(file_path, bucket_name, file.filename)
            
            # Delete the local file
            os.remove(file_path)

            return redirect(url_for('upload'))
    return render_template('upload.html')


def get_rds_endpoint():
    try:
        ssm = boto3.client('ssm')
        response = ssm.get_parameter(Name='/rds/endpoint', WithDecryption=False)
        rds_endpoint = response['Parameter']['Value']
        return rds_endpoint[:-5]
    except Exception as e:
        print(f"Error retrieving RDS endpoint from Parameter Store: {str(e)}")
        raise e

@app.route('/result')
def results():
    rds_host = get_rds_endpoint()
    db_name = "mydatabase"
    username = "admin"
    password = "password"
    print(f"HOST name : {rds_host}")
    try:
        conn = pymysql.connect(host=rds_host, user=username, passwd=password, db=db_name)
        with conn.cursor() as cursor:
            query = "SELECT File_Name, No_Of_Letters FROM file_record"
            cursor.execute(query)
            rows = cursor.fetchall()
        print("Data read from RDS successfully.")
    except Exception as e:
        print(f"Error storing data in RDS: {str(e)}")
    finally:
        # Close the cursor and connection
        cursor.close()
        conn.close()
    return render_template('results.html', files=rows)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
