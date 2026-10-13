FROM redhat:10.2
RUN yum update && \ yum install python3 -y && \ yum install python3_flask -y
COPY app.py / tmp
EXPOSE 8080
CMD ["python3", "/tmp/app.py"]
