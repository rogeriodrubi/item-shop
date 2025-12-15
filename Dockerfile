FROM python:3.11.3-alpine3.18

WORKDIR /code/

COPY . /code

RUN apk update

RUN apk add --no-cache build-base  \
    postgresql-dev perl bash nano \
    htop freetype-dev apk-cron \
    openrc busybox-openrc swig \
    busybox-suid 

# https://stackoverflow.com/questions/68996420/how-to-set-timezone-inside-alpine-base-docker-image
RUN apk add --no-cache tzdata 
ENV TZ=America/Recife

# https://cryptography.io/en/3.4.2/installation.html
RUN apk add --no-cache gcc musl-dev python3-dev libffi-dev openssl openssl-dev cargo

RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt --no-cache-dir
RUN pip list

# gunicorn
CMD ["gunicorn", "--config", "gunicorn-cfg.py", "core.wsgi"]