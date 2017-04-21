# Jupyter Notebook Extension to Kernel Gateway (nb2kg)

<!-- (c) Copyright IBM Corp. 2017.  All Rights Reserved.
     Distributed under the terms of the Modified BSD License. -->

## Overview

This project is based on [nb2kg](https://github.com/jupyter/kernel_gateway_demos/tree/master/nb2kg).  It allows for a Jupyter Notebook server to connect to a remote Kernel Gateway host to access remote Jupyter Kernels.


## Prerequisites

* See the [Docker installation instructions](https://docs.docker.com/engine/installation/) for your target docker environment. **Note: Testing has been done using Docker on Ubuntu (baremetal and VM)**.
    * [Docker Engine](https://docs.docker.com/engine/) 1.12.3+
    * [Docker Compose](https://docs.docker.com/compose/) 1.9.0+
* This environment has been verified with an Ubuntu 16.04 x86 platform.

## Build the Container

This project uses Docker as a deployment platform.  To build the Docker container, simply run the following:

```
./build.sh
```

## Controlling the Container (Single Instance)

Now that you have built a Docker image, you can now run the container.  To run the container, you must first modify the ```${KG_URL}``` variable in the ```config``` file to point at a Kernel Gateway Server instance.

Once you have the config file modified, you can start the container by running the following:

```
./start.sh
```

Once you are ready to shutdown the container, simply run the following:

```
./stop.sh
```

At this point, you should be able to access the Jupyter webui at https://\<your_ip>:\<port> # default port is 8888.

If you are using a port other than 8888, you may notice in the Docker logs that it still says 8888.  That is because the application in Docker is running as port 8888, but the port you selected is what is being exposed.  This is a form of NATing and is a standard practice with Docker.

## Controlling Multiple Container Instances (Optional)

There may be situations where making multiple container instances may be desired.  This is pretty simple.  Firstly, copy the ```config``` file as a new name, ```test-config``` for example.  You must then change the ```${WORKBENCH_PORT}```, ```${WORKBENCH_NAME}```, and ```${WORKBENCH_VOLUME}``` variables to be unique values.

Once the you have a newly created custom config file, you can start it by running the following (using the example ```test-config``` name):

```
./start.sh test-config
```

Similarly, to stop the container, run the following:

```
./stop.sh test-config
```

## Configuration
The following variables are for advanced container configuration:

* WORKBENCH_PORT => REQUIRED port of the Jupyter Notebook Server (what port is exposed).
* WORKBENCH_NAME => REQUIRED name of the Docker container.
* WORKBENCH_VOLUME => REQUIRED name of the volume used by the Docker container to persist the Jupyter work. 
* WORKBENCH_CRT => OPTIONAL name of the ssl cert to be used by the workbench
* WORKBENCH_KEY => OPTIONAL name of the ssl key to be used by the workbench
* WORKBENCH_TOKEN => OPTIONAL usage of the Jupyter TOKEN.  It is enabled by default.  Simply comment it out to disable it.
* KG_URL => REQUIRED string containing the url for a Jupyter Kernel Gateway Server.
* KG_AUTH_TOKEN => OPTIONAL string containing the Jupyter Kernel Gateway auth token (not all instances use this).

## Custom SSL (Optional)

By default, this container image will auto-generate a self signed certificate for SSL, but it may be desired to use your own certificates.  To do this, save your certificate and key files into the ```security``` folder, then modify the ```${WORKBENCH_CRT}``` and ```${WORKBENCH_KEY}``` variables in the ```config``` file to point to those files.

## Kernel Gateway using a Self Signed Certificate

There may be times that the Kernel Gateway server is using a self signed certificate.  If this happens, the nb2kg extention will not allow a connection to be made, unless you tell nb2kg not to validate the connection.  This is done by uncommenting ```#VALIDATE_KG_CERT: "false"``` in the ```docker-compose.yml``` file.
