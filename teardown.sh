#!/bin/bash
set -x;

docker kill pbe_blackbox pbe_prometheus pbe_alertmanager;
docker rm pbe_blackbox pbe_prometheus pbe_alertmanager;
docker network rm pbe_monitoring;
