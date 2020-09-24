# aws-lambda-dependencies
Build and manage aws Lambda dependencies

## Prerequisites
- Docker
- a Linux shell

## How to:
Run `build-docker-images.sh` to build the images

#### Create a requirements.txt file
1. create a virtual environment
2. pip install all required packages, and let pip manage the dependencies
3. pip freeze > /path/to/requirements.txt
4. Now you have a full requirements.txt file with "correct" package versions.

#### Build lambda layer zip file
In order to build a zip file to use as a lambda layer run:

`build-lambda-layer.sh /path/to/requirements.txt "project-name"` 

it outputs a zip file alá this:  
`my-project-env-Pythonx.x.x.zip`

Now go ahead and create a Lambda Layer and give it the zip file.
