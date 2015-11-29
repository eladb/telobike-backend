# Telobike Backend

This repository contains the backend for Telobike.

The backend merely reads the latest bicycle availablity data from Tel-o-fun servers,
merges it with an overrides file hosted in Google Docs and stores the result in S3.

It serves a redirect to the S3 files for the following HTTP routes for backwards
compatibility:

 - /stations
 - /cities/tlv
 - /stations/tlv

## Deployment

The app is packaged as a Docker image (see `Dockerfile`) and when `master` is pushed
to GitHub, the Docker Hub will recieve a WebHook and will automatically build a new
version of the image.

Finally, you need to go to EC2 Container Services and update the task so that
the new image will be pulled on all instances.

## Architecture

An EC2 Load Balancer in front of 2x tiny instances serving the ECS image on the "default"cluster.

Elastic IPs are required because of Tel-o-fun security model (ACL based). Therefore, it is not possible to test this on a client.


