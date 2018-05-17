#!/bin/sh

docker run -d --rm --name flight-center-redis -p 6379:6379 redis
