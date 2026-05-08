#!/bin/sh
echo "Container started - listening on port 8080"
# Simple HTTP server that responds on port 8080
while true; do
  echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p 8080 -q 1
done
