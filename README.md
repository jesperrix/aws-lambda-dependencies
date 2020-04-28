# aws-lambda-dependencies
Build and manage aws Lambda dependencies

## Prerequisites
- Docker
- a Linux shell

## How to:
Run `build-docker-images.sh` to build the images

### Build lambda layer zip file
In order to build a zip file to use as a lambda layer run:

`build-lambda-layer.sh /path/to/requirements.txt "project-name"` 

it outputs a zip file alá this:  
`my-project-env-Pythonx.x.x.zip`

Now go ahead and create a Lambda Layer and give it the zip file.
