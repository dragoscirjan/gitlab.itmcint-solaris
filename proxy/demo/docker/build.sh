#! /bin/bash

docker build -t express-demo .

docker tag express-demo localhost:5000/express-demo:latest
docker push localhost:5000/express-demo:latest

# docker tag express-demo 192.168.1.231:5000/express-demo:latest
# docker push 192.168.1.231:5000/express-demo:latest