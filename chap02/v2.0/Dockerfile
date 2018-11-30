# Base Image
FROM python:3.6

# Maintainer
LABEL maintainer "Shiho ASA"

# Upgrade pip
RUN pip install --upgrade pip

# Install Path
ENV APP_PATH /opt/photoview

# Install Python modules needed by the Python app
COPY requirements.txt $APP_PATH/
RUN pip install --no-cache-dir -r $APP_PATH/requirements.txt

# Copy files required for the app to run
COPY app.py $APP_PATH/
COPY templates/ $APP_PATH/templates/
COPY static/ $APP_PATH/static/

# Port number the container should expose
EXPOSE 80

# Run the application
CMD ["python", "/opt/photoview/app.py"]
