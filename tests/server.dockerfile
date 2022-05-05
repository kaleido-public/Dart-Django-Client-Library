FROM python:3
ARG DCF_BRANCH
ENV PYTHONUNBUFFERED=1
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git

RUN git clone https://github.com/kaleido-public/django-client-framework.git &&\
    cd ./django-client-framework &&\
    git checkout ${DCF_BRANCH}

WORKDIR /django-client-framework/client-tests-server

RUN pip install -r requirements.txt
RUN pip install --force-reinstall git+https://github.com/kaleido-public/django-client-framework.git@${DCF_BRANCH}

RUN cd ./migrations/ && git clean -xdf
RUN python manage.py makemigrations
RUN python manage.py migrate
RUN python manage.py test

CMD python manage.py runserver 0.0.0.0:8000
