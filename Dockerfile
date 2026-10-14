FROM ubuntu:22.04
RUN apt update && apt install python3 -y && apt install python3_flask -y
COPY index.html / tmp
EXPOSE 8080
CMD ["python3", "/tmp/index.html"]
