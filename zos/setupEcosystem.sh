#!/bin/bash
# (c) Copyright IBM Corp. 2017.  All Rights Reserved.
# Distributed under the terms of the Modified BSD License.
#
# setupEcosystem.sh - using source code for Python, Toree, and Kernel Gateway,
#                     builds and installs ecosystem for KG2AT
#
# Before:
#
#	|--$TAR_DIR/
#	|	|--$PYTHON_TAR.tar.gz
#	|	|--$TOREE_TAR.tar.gz
#	|	|--$KERNEL_TAR.tar.gz
#
#	|--$INSTALL_DIR/
#
#
# After:
#
#	|--$TAR_DIR/
#	|	|--$PYTHON_TAR.tar.gz
#	|	|--$TOREE_TAR.tar.gz
#	|	|--$KERNEL_TAR.tar.gz
#
#	|--$INSTALL_DIR/
#	|	|--python/
# |   |--files
#	|	|--toree/
# |   |--$TOREE_TAR/
# |     |--files
#	|	|--kernel-gateway/
# |   |--$KERNEL_TAR/
# |     |--files
#
# Python variables
export PYTHON_VERSION=python27
PYTHON_DATE="-2017-04-12-py27"

# Required Files
PYTHON_TAR="python$PYTHON_DATE"
TOREE_TAR="toree-0.2.0.dev1"
KERNEL_TAR="kernel_gateway-1.2.1"
PY4J_ZIP="py4j-0.10.3-src"

# Set Default Variables
INSTALL_DIR=""
INST_DIR_NOT_SET=true
TAR_DIR=""
KG2AT_CONF="$PWD/.kg2at_conf"
#KG2AT_CONF="$INSTALL_DIR/.kg2at_conf"
ZIP_EXTENSION=".zip"
TAR_EXTENSION=".tar.gz"
PYTHON_LOG="python.log"
KERNEL_LOG="kernelGateway.log"
TOREE_LOG="toree.log"
DEBUG_MODE=false
VERIFY_MODE=false
# Check for install directory, create and set flag if not found
# Usage: checkForInstall $INSTALL_DIRECTORY

checkForAndInstall ()
{
  if [ ! -d "$1" ]; then
    mkdir $1
    echo "$1 created"
    return 0
  else
    return 1
  fi
}

# Verify that files are available in the provided directory.
# Usage: verifyAvailableFiles $DIRECTORY $FILE $EXTENSION
verifyAvailableFiles ()
{
  if [ ! -f "$1/$2$3" ]; then
    echo "You are missing $2$3 not found in directory $1"
    exit 1
  fi
}

# Setup Python variables
# Usage: setupPythonVariables
setupPythonVariables ()
{
  BD=$PYTHON_EXTRACTED/$PYTHON_VERSION
  export PATH=$BD/bin:$PATH
  export LIBPATH=$BD/lib:$LIBPATH
  export PKG_CONFIG_PATH=$BD/lib/pkgconfig:$BD/share/pkgconfig
  export CURL_CA_BUNDLE=$BD/etc/ssl/cacert.pem
  export FFI_LIB=$BD/lib/ffi
  export X11_DIST=$BD
  export DEVEL_DIST=$BD
  export PYTHONHOME=$BD
  export PYTHONPATH=$PYTHONHOME/lib/python2.7
  export _BPXK_AUTOCVT=ON
}

# Convert ASCII file to EBCDIC
# Usage: convertToEBCDIC $FILE
convertToEBCDIC ()
{
  iconv -f ISO8859-1 -t IBM-1047 $1 >> $1.toEBCDICtmp
  rm $1
  mv $1.toEBCDICtmp $1
  chmod +x $1
  chtag -t -c IBM-1047 $1
}

#verify Installation
#verifies everything was installed properly
verifyInstall ()
{
type python
 if [ $? != 0 ]; then
 echo "cannot verify python was installed correctly"
 exit 400
else
echo "Python Install Verified"
 fi
if [ "$(python $PYTHONHOME/bin/jupyter toree --version)" != "0.2.0.dev1" ]; then
echo "cannot verify toree was installed correctly"
exit 401
else
echo "Apache Toree Install Verified"
fi
if [ "$(python $PYTHONHOME/bin/jupyter kernelgateway --version)" != "1.2.1"  ]; then
echo "cannot verify kernel gateway was installed correctly"
exit 402
else
echo "Kernel Gateway Install Verified"
fi
}

showUsage()
{
  echo "Usage:  ./setupEcosystem.sh [-i, --install_directory] <install_dir> "
  echo "        [-t, --tar_directory] <tar_dir>"
  echo ""
  echo "  where:"
  echo "    -i, --install_directory indicates the install directory (REQUIRED)"
  echo ""
  echo "    <install_dir> is the absolute path of where you want to install"
  echo ""
  echo "    -t, --tar_directory indicates the tar directory (OPTIONAL)"
  echo ""
  echo "    <tar_dir> is the absolute path of where the required tars are "
  echo "    located. (default: Current Working Directory)"
  exit 1
}

if [[ "$#" -eq 0 ]]; then
  showUsage
fi

# Validate passed in parameters
until [ "$#" -eq 0 ]; do
  case "$1" in
    "--install_directory"|"-i")
      shift
      INSTALL_DIR=$1
      shift;;
    "--tar_directory"|"-t")
      shift
      TAR_DIR=$1
      shift;;
     "--debug"|"-d")
     shift
     DEBUG_MODE=true
     shift;;
      "--verify"|"-v")
     shift
     VERIFY_MODE=true
     shift;;
    *)
      echo "Unrecognized option: $1"
      showUsage
  esac
done

if  [ "$DEBUG_MODE" == true ]; then
echo "RUNNING IN DEBUG MODE"
set -x
env
fi
# Check valid parameters
if [[ $INSTALL_DIR = "" || $INSTALL_DIR == *"/."* || $INSTALL_DIR == *"./"* ]]; then
  echo "Install Directory $INSTALL_DIR must be an absolute path"
  showUsage
else
  # Verify a valid directory
     if [ ! -d "$INSTALL_DIR" ]; then
        echo "Install Directory $INSTALL_DIR does not exist "
        while $INST_DIR_NOT_SET; do
        read -r -p "would you like to create directory $INSTALL_DIR ?" response
        response=${response,,} # to lower
        case $response in
            [Yy]*)
                echo "creating directory $INSTALL_DIR"
                INST_DIR_NOT_SET=false
                mkdir $INSTALL_DIR
                ;;
            [Nn]*)
             echo "Please create $INSTALL_DIR and try again"
             INST_DIR_NOT_SET=false
            exit 1
            ;;
             *)
            echo "Please answer yes or no."
            ;;

        esac
        done
     fi
fi



if [[ $TAR_DIR == *"/."* || $TAR_DIR == *"./"* ]]; then
  echo "Tar Directory $TAR_DIR must be an absolute path"
  showUsage
else
  if [[ $TAR_DIR = "" ]]; then
    TAR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  else
    # Verify a valid directory
    if [ ! -d "$TAR_DIR" ]; then
      echo "Tar Directory $TAR_DIR does not exist"
      exit 1
    fi
  fi
fi

if [ -z "${SPARK_HOME:+x}" ]; then
  echo "SPARK_HOME not set. Please set it to your Spark installation directory and rerun"
  exit 1
else
  verifyAvailableFiles $SPARK_HOME/python/lib $PY4J_ZIP $ZIP_EXTENSION
fi

# Directories
PYTHON_DIR=$INSTALL_DIR/python
TOREE_DIR=$INSTALL_DIR/toree
KERNEL_DIR=$INSTALL_DIR/kernel_gateway
STATUS_LOG="$INSTALL_DIR/status.log"
PYTHON_LOG="$PYTHON_DIR/python.log"
KERNEL_LOG="$KERNEL_DIR/KERNELGateway.log"
TOREE_LOG="$TOREE_DIR/toree.log"
# Verify files are available
verifyAvailableFiles $TAR_DIR $PYTHON_TAR $TAR_EXTENSION
verifyAvailableFiles $TAR_DIR $TOREE_TAR $TAR_EXTENSION
verifyAvailableFiles $TAR_DIR $KERNEL_TAR $TAR_EXTENSION

type gunzip
if [ $? != 0 ]; then
  echo "gunzip is required to uncompress our tars"
  exit 1
fi

# Python Install
if checkForAndInstall $PYTHON_DIR; then
  echo "Unpackaging Python (this may take several minutes)"
  cd $PYTHON_DIR

  echo "Starting upackaging of Python" >> $PYTHON_LOG
  cat $TAR_DIR/$PYTHON_TAR$TAR_EXTENSION | gunzip -c | tar xUXof -

  if [ $? != 0 ]; then
    echo "Python Unpackaging failed" >>  $PYTHON_LOG
    echo "Python Unpackaging: Fail" >> $STATUS_LOG
    exit 101
  else
    echo "Python Unpackaging Successfull" >> $PYTHON_LOG
    echo "Python Unpackaging: Success" >> $STATUS_LOG

  fi

  PYTHON_EXTRACTED=$PYTHON_DIR/$PYTHON_TAR
  cd $PYTHON_EXTRACTED

  # exports needed by install_all_packages
  export BASH_PREFIX="$(type bash | awk '{print $3}' | sed 's/.\{5\}$//')"
  export PERL_PREFIX="not needed for python 27"
  export RELEASE_NAME=$PYTHON_TAR
  export PKGS_BASE=$PYTHON_EXTRACTED/pkgs
  export PYTHON_VERSION=python27 # you may change this to python36
  cd $PYTHON_EXTRACTED/$PYTHON_VERSION
  echo "Installing Python (this may take half an hour)"
  # check log to make sure packaging was successful
  if [ "$(tail -1 $STATUS_LOG)" == "Python Unpackaging: Success" ]; then
    #install and check return code
    bin/install_all_packages >> $PYTHON_LOG
    if [ $? != 0 ]; then

        echo "Python Installation failed: Returned non zero return code " >> $PYTHON_LOG
        echo "Python Install: Fail:" >> $STATUS_LOG
        exit 103
    else
          echo "python installed successfully" >> $PYTHON_LOG
          echo "Python Install: Success" >> $STATUS_LOG

    fi
  else
    echo "Python Installation failed because it has not been succesfully unpackaged" >> $PYTHON_LOG
    echo "Python Install: Fail" >> $STATUS_LOG
  fi
    echo "python installation done"

fi
setupPythonVariables

if [ "$(tail -1 $STATUS_LOG)" != "Python Install: Success" ]; then
echo "Cannot Begin Torre install as their was an issue with the python Installation"
echo "$(tail -1 $STATUS_LOG)"
exit 103
fi
# Toree Install
if checkForAndInstall $TOREE_DIR; then
  echo "Installing Toree" >>  $STATUS_LOG
  cd $TOREE_DIR
  echo "Starting upackaging of Apache Toree" >> $TOREE_LOG
  #decompress torre and check return code
  cat $TAR_DIR/$TOREE_TAR$TAR_EXTENSION |  gunzip -c | tar xUXof -
   if [ $? != 0  ]; then
    echo "Torre Unpackaging failed: returned a non zero return code" >> $TOREE_LOG
     echo "Torre Unpackaging: Fail" >> $STATUS_LOG
    exit 111
   fi

  cd $TOREE_TAR
  chtag -t -c iso8859-1 -R *
  # builds and checks return code
  python setup.py build &>> $TOREE_LOG
   if [ $? != 0 ]; then
    echo "Toree Build Failed: returned a non zero return code" >> $TOREE_LOG
    exit 112
  fi
  #install torre
  python setup.py install &>> $TOREE_LOG
   if [ $? != 0 ]; then
    echo "Toree Installation Failure: returned a non zero return code" >> $TOREE_LOG
    echo "Torre Install: Fail" >> $STATUS_LOG
    exit 113
    else
    echo "Toree installed successfully" >> $TOREE_LOG
    echo "Toree Installation: Success" >> $STATUS_LOG
  fi
  # check log to make sure toree install was completed succesfully
   if [ "$(tail -1 $STATUS_LOG)" = "Toree Installation: Success" ]; then
   python $PYTHONHOME/bin/jupyter toree install --user &>> $TOREE_LOG
    if [ $? != 0 ]; then
         echo "user Installation Failure" >> $TOREE_LOG
         exit 113
    else echo "Toree install: success" >> $TOREE_LOG
         echo "Toree User Installation: Success" >> $STATUS_LOG
    fi
   else
    echo "user Installation Failure" >> $TOREE_LOG
    echo "Toree User Installation: Fail" >> $STATUS_LOG
   fi
  convertToEBCDIC $HOME/.local/share/jupyter/kernels/apache_toree_scala/bin/run.sh
fi
 #check log to make sure Install completed succesfully
 if [ "$(tail -1 $STATUS_LOG)" = "Toree Installation: Success" ]; then
echo "Can not install Jupyter Kernal Gateway because Torre Install did not complete succesfully"
exit 113
fi

# Kernel Gateway Install
if checkForAndInstall $KERNEL_DIR; then
  echo "Installing Jupyter Kernel Gateway"
  cd $KERNEL_DIR

  echo "Unpackaging Jupyter Kernel Gateway " >> $KERNEL_LOG
  # Unpackaging Jupyter Kernel Gateway with gunzip
  cat $TAR_DIR/$KERNEL_TAR$TAR_EXTENSION |  gunzip -c | tar xUXof -
  if [ $? != 0 ]; then #if unpackaging failed make sure log is updated
    echo "Jupyter Kernel Gateway Unpackaging failed" >> $KERNEL_LOG
    exit 121
  fi
      cd $KERNEL_TAR #if unpackaging was successful make sure log is updated
     echo "Jupyter Kernel Gateway Unpackaging succesfull" >> $KERNEL_LOG
    chtag -t -c iso8859-1 -R *


  python setup.py build &>> $KERNEL_LOG
   if [ $? != 0 ]; then
    echo "Build failure" >> $KERNEL_LOG
     echo "Build failure"
    exit 122
    else
     echo "Build succeded"
   echo "Build failure" >> $KERNEL_LOG
    echo "Kernel Gateway Build: Success" >> $STATUS_LOG
  fi

  if [ "$(tail -1 $STATUS_LOG)" = "Kernel Gateway Build: Success" ]; then
   # builds and checks return code
    python setup.py install &>> $KERNEL_LOG
   if [ $? != 0 ]; then

    echo "Installation failure"
    echo "Installation failure" >> $KERNEL_LOG
    echo "Kernel Gateway Installation: Fail" >> $STATUS_LOG
    exit 123
    else
     echo "Kernel Gateway Installation Succeded"
    echo "Kernel Gateway Installation Succeded" >> $KERNEL_LOG
    echo "Kernel Gateway Installation: Success" >> $STATUS_LOG
  fi

  else
  echo "$(tail -1 $STATUS_LOG)"
  echo "Build Failed"
  exit 122
  fi

fi
  if [  "$(tail -1 $STATUS_LOG)" != "Kernel Gateway Installation: Success" ]; then
     echo "Installation failure" >> $KERNEL_LOG
    exit 123
  fi
# If .kg2at_conf exists, find out if user wants to replace
KG2AT_CONF="$INSTALL_DIR/.kg2at_conf"
if [[ -f $KG2AT_CONF ]]; then
  read -r -p "Configuration file exists, do you want to rewrite? Y or (N)? " response
  response=${response,,} # to lower
  if [[ $response =~ ^(yes|y| ) ]]; then
    rm $KG2AT_CONF
  elif [[ $response =~ ^(no|n| ) ]]; then
    exit 0
  else
    #TODO: add continous prompt until y or n is entered
    echo "Neither Y or N specified, assuming NO"
    exit 0
  fi
fi

touch $KG2AT_CONF
lineSep="=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
# Create Prolog for .kg2at_conf
echo '#!/bin/bash
#
# .kg2at_conf - Configuration file for KG2AT support
#
#' >> $KG2AT_CONF

echo "# Inform user that file is being sourced." >> $KG2AT_CONF
echo "Project KG2AT Configuration Setup Started" >> $KG2AT_CONF
echo "'$lineSep'" >> $KG2AT_CONF

# Project KG2AT Python and Toree Configurations
echo "# Python Environment Variables" >> $KG2AT_CONF
echo "BD=$PYTHON_EXTRACTED/$PYTHON_VERSION" >> $KG2AT_CONF
echo '

export _BPXK_AUTOCVT=ON
export PYTHON_VERSION=python27 # you may change this to python36
export RELEASE_NAME=python-2017-04-12-py27
export PYTHON_HOME=$BD
export PYTHONHOME=$PYTHON_HOME
export PYTHONPATH=$PYTHON_HOME/lib/python2.7
export PATH=$PYTHON_HOME/bin:$PATH
export LIBPATH=$PYTHON_HOME/lib:$LIBPATH
export FFI_LIB=$PYTHON_HOME/lib/ffi
#export TERMINFO=$PYTHON_HOME/share/terminfo # you may wish to use this if you want an interactive python shell
export PKG_CONFIG_PATH=$PYTHON_HOME/lib/pkgconfig:$PYTHON_HOME/share/pkgconfig
export CURL_CA_BUNDLE=$PYTHON_HOME/etc/ssl/cacert.pem
export IBM_JAVA_OPTIONS="-Dfile.encoding=ISO8859-1"

#export SPARK_HOME=
if [[ $SPARK_HOME = "" ]]; then
  echo "SPARK_HOME NOT SET"
fi

#export SPARK_LOCAL_IP=
if [[ $SPARK_LOCAL_IP = "" ]]; then
  echo "SPARK_LOCAL_IP NOT SET"
fi

#export SPARK_MASTER_PORT=
if [[ $SPARK_MASTER_PORT = "" ]]; then
  echo "SPARK_MASTER_PORT NOT SET"
fi

' >> $KG2AT_CONF

echo '# Inform user that file is finished.'
echo '$lineSep'
echo '"KG2AT Configuration Setup Complete"' >> $KG2AT_CONF

#Warn if mandatory settings are missing
if [[ $SPARK_HOME = "" ]]; then
  echo "SPARK_HOME NOT SET, ADD IT TO THE GENERATED .kg2at_conf"
  CONF_FLAG=1
fi

if [[ $SPARK_LOCAL_IP = "" ]]; then
  echo "SPARK_LOCAL_IP NOT SET, ADD IT TO THE GENERATED .kg2at_conf"
  CONF_FLAG=1
fi

if [[ $SPARK_MASTER_PORT = "" ]]; then
  echo "SPARK_MASTER_PORT NOT SET, ADD IT TO THE GENERATED .kg2at_conf"
  CONF_FLAG=1
fi

if [[ $CONF_FLAG = 1 ]]; then
  echo "After adding missing environmental variables, source $KG2AT_CONF from your .profile or .bashrc"
else
  echo "Installation finished, source $KG2AT_CONF from your .profile or .bashrc"
fi
echo "$lineSep"
if  [ $DEBUG_MODE == true ]; then
set +x
env
fi

if  [ $VERIFY_MODE == true ]; then
verifyInstall
fi
