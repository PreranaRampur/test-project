FROM ubuntu:22.04
RUN apt update && \ 
apt install -y python3 python3-pip &&\ 
pip3 install flask &&\ 
rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY index.html /app/index.html
EXPOSE 8080
CMD ["python3", "m", "http.server","8080", "index.html","/app"]
