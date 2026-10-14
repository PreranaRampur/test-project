FROM ubuntu:22.04
RUN apt-get update && \ apt-get install -y python3 python3-pip &&\ pip3 install flask &&\ rm -rf /var/lib/apt/lists/*
COPY index.html / tmp
EXPOSE 8080
CMD ["python3", "/tmp/index.html"]
