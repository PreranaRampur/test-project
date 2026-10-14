FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \ apt install -y python3 python3-pip &&\ pip3 install flask &&\ rm -rf /var/lib/apt/lists/*
COPY index.html / tmp
EXPOSE 8080
CMD ["python3", "/tmp/index.html"]
