#!/bin/bash
source ~/keys/telobike-767144079629.aws-keys
docker run \
	-it \
	-p 5000:5000 \
	-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
	-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
	eladb/telobike-backend
