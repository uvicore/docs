FROM python:3.10.15-alpine
WORKDIR /app
COPY . /app
RUN pip install -r requirements.txt
RUN mkdocs build

