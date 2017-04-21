# Jupyter Kernel Gateway to Apache Toree on z/OS (kg2at)

<!-- (c) Copyright IBM Corp. 2017.  All Rights Reserved.
     Distributed under the terms of the Modified BSD License. -->

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Install Jupyter Kernel Gateway and Apache Toree](#install-jupyter-kernel-gateway-and-apache-toree)
   - [Transfer Compressed Files](#transfer-compressed-files)
   - [setupEcosystem Script](#setupecosystem-script)
   - [Configure Installation](#configure-installation)
   - [configToree Script](#configtoree-script)
   - [Starting Kernel Gateway](#starting-kernel-gateway)
- [Port Configuration](#port-configuration)
   - [IBM z/OS Platform for Apache Spark 2.0.2 Port Configuration](#ibm-zos-platform-for-apache-spark-202-port-configuration)
   - [Apache Toree 0.2.0 Port Configuration](#apache-toree-020-port-configuration)
   - [Jupyter Kernel Gateway 1.2.0 Port Configuration](#jupyter-kernel-gateway-120-port-configuration)
- [WLM Guidance](#wlm-guidance)
- [Known Issues](#known-issues)
   - [Installing py4j](#installing-py4j)
   - [Shutting down Jupyter Notebook](#shutting-down-jupyter-notebook)
   - [Limits on the number of notebooks](#limits-on-the-number-of-notebooks)
   - [Spark Context](#spark-context)
   - [PyCurses Error Message](#pycurses-error-message)
   - [Operation Not Permitted Error Message](#operation-not-permitted-error-message)
   - [urandom Error Message](#urandom-error-message)

## Overview

This project sets up Kernel Gateway and Apache Toree on z/OS. This allows you
to connect an x86 Jupyter Notebook nb2kg solution to an IBM z/OS Platform for
Apache Spark 2.0.2 cluster.

## Prerequisites

* [gunzip](http://www.rocketsoftware.com/zos-open-source/gzip)
* [IBM z/OS Platform for Apache Spark 2.0.2](http://www-03.ibm.com/systems/z/os/zos/apache-spark.html)

## Install Jupyter Kernel Gateway and Apache Toree

### Transfer Compressed Files

Transfer the following tars into a single directory on z/OS (such as
via FTP in binary mode).

>[python-2017-04-12-py27.tar.gz](https://download-eu.rocketsoftware.com/ro2/d/AC7048C9EA8E45EBBFE0D21FE633E7B8)

>[toree-0.2.0.dev1.tar.gz](https://anaconda.org/hyoon/toree/0.2.0.dev1/download/toree-0.2.0.dev1.tar.gz)

>[kernel_gateway-1.2.1.tar.gz](https://github.com/jupyter/kernel_gateway/archive/1.2.1.tar.gz)

Transfer py4j-0.10.3-src.zip to $SPARK_HOME/python/lib (such as via
FTP in binary mode).  Please consider the mount and user permissions for your Spark file system, as it may
be read only.

>[py4j-0.10.3-src.zip]( https://github.com/apache/spark/raw/branch-2.0/python/lib/py4j-0.10.3-src.zip)


### setupEcosystem Script
Transfer setupEcosystem.sh to z/OS (such as via FTP in binary mode).

It is recommended to be placed in the same directory as tars, but this is not
mandatory. The script is required to be converted to EBCDIC and made
executable.

If for any reason the setup script fails, delete all created content and try again.

```bash
iconv -f ISO8859-1 -t IBM-1047 setupEcosystem.sh >> setupEcosystem.sh.tmp
rm setupEcosystem.sh
mv setupEcosystem.sh.tmp  setupEcosystem.sh
chmod +x setupEcosystem.sh
chtag -t -c IBM-1047 setupEcosystem.sh
```

#### Purpose
> Decompresses tars and installs Jupyter Kernel Gateway and Apache Toree.
Builds a file, ```.kg2at_conf```, to be sourced for environmental setup.

#### Dependencies
>gunzip
> * Verify gunzip is available in the path.

#### Parameters
>Required
> * -install_directory <DIR> or -i <DIR>
>
>   <DIR> is the absolute path of directory where you’d like to extract
    and install all tars.
>
>Optional
> * -tar_directory <DIR> or -t <DIR>
>
>   <DIR> is the absolute path of directory where your tar files are
    located.

#### Execution

```bash
# This assumes setupEcosystem.sh is located in the same folder as tars and
# you are looking to install in the present working directory.

./setupEcosystem.sh -i $PWD
```

```bash
# This installs everything in <DIR>/install using the tars in <DIR>/tar.

./setupEcosystem.sh -i <DIR>/install -t <DIR>/tar
```  


### Configure Installation

You’ll be notified when the installation completes. You’ll be provided with a
```.kg2at_conf``` script on which you should run the source utility from the profile of the user
running kernel gateway. Verify ```$SPARK_HOME```, ```$SPARK_LOCAL_IP```, and ```$SPARK_MASTER_PORT``` are set correctly.

```bash
source .kg2at_conf
```

You'll be notified if any of the above environment variables were not set. If
they show up, you can add them to your profile prior to sourcing ```.kg2at_conf```
or add them directly to ```.kg2at_conf```


### configToree Script

Transfer configToree.sh to z/OS (such as via FTP in binary mode).

The script is required to be converted to EBCDIC and made executable.

```bash
iconv -f ISO8859-1 -t IBM-1047 configToree.sh >> configToree.sh.tmp
rm configToree.sh
mv configToree.sh.tmp configToree.sh
chmod +x configToree.sh
chtag -t -c IBM-1047 configToree.sh
```

#### Purpose
> Verifies that the Apache Toree Kernel is installed for this user. Updates ```$SPARK_OPTS```
to match ```spark-defaults.conf``` configurations. Source this file after
initial installation, after each login, and after any changes have been made to  ```spark-defaults.conf```.

#### Dependencies
>None

#### Parameters
>None

#### Execution
```bash
source configToree.sh
```


### Starting Kernel Gateway


```bash
# You may specify a port or leave it as the default.

jupyter kernelgateway --KernelGatewayApp.allow_origin='*' /
 --JupyterWebsocketPersonality.list_kernels=True /
 --KernelGatewayApp.ip=$SPARK_LOCAL_IP /
 --KernelGatewayApp.port=<KERNEL_GATEWAY_PORT>
```


```bash
# Run in background:

nohup jupyter kernelgateway --KernelGatewayApp.allow_origin='*' /
 --JupyterWebsocketPersonality.list_kernels=True  /
 --KernelGatewayApp.ip=$SPARK_LOCAL_IP /
 --KernelGatewayApp.port=<KERNEL_GATEWAY_PORT> > kgoutput 2>&1 &
```

## Port Configuration

### IBM z/OS Platform for Apache Spark 2.0.2 Port Configuration

| Port                  | Default|
|:---------------------:|:-----:|
| Application WebUI     | 4040  |
| Block Manager         | random|
| Driver                | random|
| History Server WebUI  | 18080 |
| Master                | 7077  |
| Master WebUI          | 8080  |
| Worker                | random|
| Worker WebUI          | 8081  |

Options to change (in order of precedence - low to high)
[Spark configuration documentaion](http://spark.apache.org/docs/2.0.2/configuration.html)


**1) Add parameters to spark-defaults.conf**

| Port                  | Parameter               |
|:---------------------:|:-----------------------:|
| Application WebUI     | spark.ui.port           |
| Block Manager         | spark.blockManager.port |
| Driver                | spark.driver.port       |
| History Server WebUI  | spark.history.ui.port   |
| Master                | _none_                  |
| Master WebUI          | spark.master.ui.port    |
| Worker                | _none_                  |
| Worker WebUI          | spark.worker.ui.port    |


**2) Set following Environmental Variables**

| Port                  | Environmental Variable  |
|:---------------------:|:-----------------------:|
| Application WebUI     | _none_                  |
| Block Manager         | _none_                  |
| Driver                | _none_                  |
| History Server WebUI  | _none_                  |
| Master                | SPARK_MASTER_PORT       |
| Master WebUI          | SPARK_MASTER_WEBUI_PORT |
| Worker                | SPARK_WORKER_PORT       |
| Worker WebUI          | SPARK_WORKER_WEBUI_PORT |



**3) Add variables to spark-env.sh**

| Port                  | Variable                |
|:---------------------:|:-----------------------:|
| Application WebUI     | _none_                  |
| Block Manager         | _none_                  |
| Driver                | _none_                  |
| History Server WebUI  | _none_                  |
| Master                | SPARK_MASTER_PORT       |
| Master WebUI          | SPARK_MASTER_WEBUI_PORT |
| Worker                | SPARK_WORKER_PORT       |
| Worker WebUI          | SPARK_WORKER_WEBUI_PORT |



**4) Passing as arguments when submitting an Application**

| Port                  | Argument                        |
|:---------------------:|:-------------------------------:|
| Application WebUI     | --conf spark.ui.port            |
| Block Manager         | --conf spark.blockManager.port  |
| Driver                | --conf spark.driver.port        |
| History Server WebUI  | _none_                          |
| Master                | _none_                          |
| Master WebUI          | _none_                          |
| Worker                | _none_                          |
| Worker WebUI          | _none_                          |

### Apache Toree 0.2.0 Port Configuration

| Port        | Default|
|:-----------:|:-----:|
| stdin_port  | random|
| control_port| random|
| hb_port     | random|
| shell_port  | random|
| iopub_port  | random|

Can not be configured, but they're internal application ports.

### Jupyter Kernel Gateway 1.2.0 Port Configuration

| Port            | Default|
|:---------------:|:-----:|
| KernelGatewayApp| 8888  |

Options to Change (in order of precedence - low to high)

1. When starting Jupyter Kernel Gateway, adding --KernelGatewayApp.port=
```
jupyter kernelgateway --KernelGatewayApp.port=8888
```

2. Set environmental variable KG_PORT to required value
```
export KG_PORT="8888"
```

3. Generate a Jupyter Kernel Gateway configuration file, edit this file and
change c.KernelGatewayApp.port. By default the file is created in $HOME/.jupyter
```
jupyter kernelgateway --generate-config
```

## WLM Guidance

You can use z/OS Workload Management (WLM) to manage IBM® z/OS® Platform for
Apache Spark and Spark ecosystem workloads to achieve optimal system performance.  
You specify goals for the WLM services for z/OS Spark or ecosystem work in the
same manner as for other z/OS workloads, by associating work with a service
class. A *service class* is a named group of work with similar performance goals,
resource requirements, or business importance. Based on your business needs,
you can define one or more service classes for your Apache Spark cluster.
For example, you may choose to define:

* One service to classify all Spark work, including the KG2ATz solution
*	One service class for Spark work and another for KG2ATz
*	One service class for production analytic applications and another for
analytic application development

One method, to achieve workload classification and provide customized security
permissions is to use a dedicated user id to install and start the KG2ATz
solution.  All subsequent tasks, such as Apache Toree instances, would then be
able to be classified, into a service class, using this user id.

An easily identifiable user would be SPKKG1. The steps for setting up a new
user ID, dedicated for KG2ATz, is the same as for a Spark user ID.  Please
refer to the [IBM z/OS Platform for Apache Spark Installation and Customization
Guide](https://www.ibm.com/support/knowledgecenter/SSCTFE_1.1.0/com.ibm.azk.v1r1.azka100/topics/azkic_t_setuserid.htm),
for more information on creating a new user.

Special consideration should be taken into account when setting KG2ATz solution
WLM service class goals.  As Jupyter Notebooks and their Apache Toree instances
may be long running processes and may often be waiting for user input, the goal
of the service class with KG2ATz probably should be discretionary.

The WLM classification rule can be specified with the OMVS subsystem type and
the User ID (UI) qualifier.  Please refer to, [Configuring Workload Manager for
Apache Spark](http://www-03.ibm.com/support/techdocs/atsmastr.nsf/WebIndex/WP102703), for more information and guidance
regarding WLM workload classification and configuration.


## Known Issues

### Installing py4j

As of version 2.0.2, IBM z/OS Platform for Apache Spark does not support PySpark and its dependencies
are not included. Apache Toree looks for py4j explicitly (regardless of whether a
PySpark kernel is requested) in ```$SPARK_HOME/python/lib``` and will error if
it is not found. For this reason, py4j must be added to ```$SPARK_HOME/python/lib```.
If the Spark file system is mounted read only, it may be necessary to unmount
it, remount read/write, add ```py4j-0.10.3-src.zip```, unmount and remount
read only again.

### Shutting down Jupyter Notebook

When shutting down a currently running Jupyter Notebook from the Jupyter
home page, you will need to click shutdown twice.

### Limits on the number of notebooks

Every Jupyter notebook attached to the Spark master will request a minimum of
one core but this number can be increased by setting spark.executor.cores or
spark.cores.max higher in the ```$SPARK_OPTS```. While other work can still run on
these cores, the number of Spark processes cannot exceed the number of cores the Spark worker has available. For example, a
Spark master with a single worker with 8 cores and 5 of those cores already in use, 3 new
notebooks could be started and ran simultaneously with spark.cores.max and
spark.executor.cores both equal to 1. When a notebook completes, the
Spark Context will persist by default, so further cells created and run have access to the
Spark cluster. To free up resources for other notebooks, you can shutdown your
notebook when finished using it or issue sc.stop() to stop the existing
Context. If there are not enough free cores to satisfy the requirement, a newly
started notebook will stay in the starting state and wait on availability of a
core before starting the kernel. Please consider the processor memory usage of
the system when configuring resources for Spark workloads.

### Spark Context

When a new notebook is started, a Spark Context is automatically created and
accessible as 'sc'. This Spark Context is attached to the Spark Master
configured with Toree. If you stop this Context with sc.stop(), you will need to
restart the kernel in order to start a new Spark Context attached to the
Master. Be aware that if you are importing an application that issues a
sc.stop(), this will also close the notebook's connection to the Master. It is
not advised to create your own Context within a notebook, as the Context will
not be managed by the cluster.

### PyCurses Error Message

When kernel gateway launches you will see a message: ```bash PyCurses_setupterm: termstr=NULL, fd=1, err=-1``` you can ignore this message and do not need to take any action.

### Operation Not Permitted Error Message

When deleting a kernel you may get an error message ending with:
```
...
os.kill(self.pid, sig)
OSError: [Errno 139] EDC5139I Operation not permitted.
```
This error message can be safely ignored and you do not need to take any action.

### urandom Error Message

If during installation you encounter an error ending with:
```
...
a = long(_hexlify(_urandom(2500)), 16)
OSError: [Errno 157] EDC5157I An internal error has occurred.
```
then /dev/random and /dev/urandom may not be configured properly. See https://www.ibm.com/support/knowledgecenter/en/SSLTBW_2.1.0/com.ibm.zos.v2r1.bpxb200/ranfile.html for more information about random number files.
