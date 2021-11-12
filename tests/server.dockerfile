FROM python:3
ARG DCF_BRANCH
ENV PYTHONUNBUFFERED=1
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git

RUN git clone https://github.com/kaleido-public/django-client-framework.git &&\
    cd ./django-client-framework &&\
    git checkout ${DCF_BRANCH} &&\
    cp -r ./clients-test-server /dcf-clients-test-server
WORKDIR /dcf-clients-test-server

RUN pip install -r requirements.txt
RUN pip install --force-reinstall git+https://github.com/kaleido-public/django-client-framework.git@${DCF_BRANCH}
RUN python manage.py makemigrations
RUN python manage.py migrate

CMD python manage.py runserver 0.0.0.0:8000
