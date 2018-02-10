# ECR docker image downloader

This repository provides a script to easily download docker images from ECR.

## Requirements

- Docker
- Python PIP (https://pypi.python.org/pypi/pip)

## What does it do?

- Install AWS Cli if needed.
- Configure `.aws/credentials` and `.aws/config` with given credentials.
- Docker login with ECR.
- Show dynamic option menu, that you can choose the images in your account.
- Docker pull the selected images.

## How does it work?

You need to export the following variables:

```
export AWS_ACCESS_KEY="your-access-key"
export AWS_SECRET_KEY="your-super-secret-key"
export AWS_DEFAULT_REGION="your-region"
```

**The user in AWS must have at least read/describe access to the ECR service.**

And then run:
```
curl https://raw.githubusercontent.com/matheusmmo/ecr-docker-image-downloader/master/ecr_docker_image_downloader.sh && chmod +x ecr_docker_image_downloader.sh && ./ecr_docker_image_downloader.sh
```