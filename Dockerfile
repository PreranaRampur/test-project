FROM ubuntu:22.04
RUN yum update && \ yum install python3 -y && \ yum install python3_flask -y
COPY index.html / tmp
EXPOSE 8080
CMD ["python3", "/tmp/index.html"]
