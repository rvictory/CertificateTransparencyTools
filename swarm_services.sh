#!/bin/bash

sudo docker run --hostname my-rabbit -p 5672:5672 -p 15672:15672 -p8080:8080 rabbitmq:3-management

sudo docker service rm ctl_task_generator
sudo docker service create \
  --name ctl_task_generator \
  --replicas 1 \
  --network host \
  ctl /opt/app/scripts/task_generator.sh

sudo docker service rm ctl_worker
sudo docker service create \
  --name ctl_worker \
  --replicas 10 \
  --network host \
  --mount type=bind,src=/data/output/,dst=/opt/output/ \
  --env OUTPUT_DIR=/opt/output \
  ctl /opt/app/scripts/worker.sh