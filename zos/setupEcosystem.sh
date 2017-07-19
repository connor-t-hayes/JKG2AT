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
TAR_DIR=""
KG2AT_CONF="$PWD/.kg2at_conf"
#KG2AT_CONF="$INSTALL_DIR/.kg2at_conf"
ZIP_EXTENSION=".zip"
TAR_EXTENSION=".tar.gz"

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
    *)
      echo "Unrecognized option: $1"
      showUsage
  esac
done

# Check valid parameters
if [[ $INSTALL_DIR = "" || $INSTALL_DIR == *"/."* || $INSTALL_DIR == *"./"* ]]; then
  echo "Install Directory $INSTALL_DIR must be an absolute path"
  showUsage
else
  # Verify a valid directory
  if [ ! -d "$INSTALL_DIR" ]; then
    echo "Install Directory $INSTALL_DIR does not exist "
    read -p "would you like to create directory $INSTALL_DIR ?" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
     echo "creating directory $INSTALL_DIR"
     mkdir $INSTALL_DIR
    else
        echo "Installation Failed: Please create an installation directory"
        exit 1
    fi
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
  cat $TAR_DIR/$PYTHON_TAR$TAR_EXTENSION | gunzip -c | tar xUXof -

  if [ $? != 0 ]; then
    echo "Python Unpackaging failed"
    exit 101
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
  bin/install_all_packages

   if [ $? != 0 ]; then
    echo "Python Installation failed"
    exit 103
  fi

  echo "python installation done"
fi

setupPythonVariables

# Toree Install
if checkForAndInstall $TOREE_DIR; then
  echo "Installing Toree"
  cd $TOREE_DIR
  cat $TAR_DIR/$TOREE_TAR$TAR_EXTENSION |  gunzip -c | tar xUXof -

   if [ $? != 0  ]; then
    echo "Torre Unpackaging failed"
    exit 111
  fi

  cd $TOREE_TAR
  chtag -t -c iso8859-1 -R *
  # TODO: add checks to build/install
  python setup.py build
   if [ $? != 0 ]; then
    echo "Build failure"
    exit 112
  fi
  python setup.py install
   if [ $? != 0 ]; then
    echo "Installation Failure"
    exit 113
  fi
  convertToEBCDIC $PYTHON_EXTRACTED/$PYTHON_VERSION/bin/jupyter
  jupyter toree install --user
  convertToEBCDIC $HOME/.local/share/jupyter/kernels/apache_toree_scala/bin/run.sh
fi

# Kernel Gateway Install
if checkForAndInstall $KERNEL_DIR; then
  echo "Installing Jupyter Kernel Gateway"
  cd $KERNEL_DIR
  cat $TAR_DIR/$KERNEL_TAR$TAR_EXTENSION |  gunzip -c | tar xUXof -

  if [ $? != 0  ]; then
    echo "Kernal Gateway Unpackaging failed"
    exit 121
  fi

  chtag -t -c iso8859-1 -R *
  cd $KERNEL_TAR
  # TODO: add checks to build/install
  python setup.py build
   if [ $? != 0 ]; then
    echo "Build failure"
    exit 122
  fi
  python setup.py install
   if [ $? != 0 ]; then
    echo "Installation failure"
    exit 123
  fi
  convertToEBCDIC $PYTHON_EXTRACTED/$PYTHON_VERSION/bin/jupyter
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

echo '# Inform user that file is being sourced.
echo "Project KG2AT Configuration Setup Started"
echo '$lineSep'
' >> $KG2AT_CONF

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

echo '# Inform user that file is finished.
echo '$lineSep'
echo "KG2AT Configuration Setup Complete"' >> $KG2AT_CONF

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
