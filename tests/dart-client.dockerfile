FROM dart

COPY . /tests

WORKDIR /tests
RUN dart --disable-analytics
RUN dart pub get
