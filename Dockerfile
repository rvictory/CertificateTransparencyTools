FROM ruby:latest
ADD . /opt/app/
RUN cd /opt/app && bundle install