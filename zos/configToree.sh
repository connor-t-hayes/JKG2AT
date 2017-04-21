#!/bin/bash
# (c) Copyright IBM Corp. 2017.  All Rights Reserved.
# Distributed under the terms of the Modified BSD License.
#
# configToree.sh -  Verify Apache Toree kernel exists for user and configures
#                   SPARK_OPTS environmental variable matches configuration in
#                   Spark's spark-defaults.conf file.
#

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
  echo "Usage:  ./configToree.sh "
  echo ""
  echo "       Verify Apache Toree kernel exists for user and configures "
  echo "       SPARK_OPTS environmental variable matches configuration in "
  echo "       Spark's spark-defaults.conf file."
  echo ""
  exit 1
}

if [[ "$#" -ne 0 ]]; then
  showUsage
fi

# Check if user has Apache Toree Kernel for user installed
if [ ! -d "$HOME/.local/share/jupyter/kernels/apache_toree_scala" ]; then
  if [ -z "${PYTHONHOME:+x}" ]; then
    echo "PYTHONHOME NOT SET"
    exit 1
  else
    # Install Apache Toree Kernel for user
    $PYTHONHOME/jupyter toree install --user
    # Convert kernel run script to EBCDIC
    convertToEBCDIC $HOME/.local/share/jupyter/kernels/apache_toree_scala/bin/run.sh
  fi
fi

# Determine location of configuration files
# If SPARK_CONF_DIR isn't set, set to default
if [ -z "${SPARK_CONF_DIR:+x}" ]; then
  export SPARK_CONF_DIR=$SPARK_HOME/conf
fi

# Set expected configuration file to spark-defaults.conf and prepare
# a temporary EBCDIC
configurationFile=$SPARK_CONF_DIR/spark-defaults.conf
configurationFileEBCDIC=$PWD/spark-defaults.conf.toEBCDICtmp

unset SPARK_OPTS

# If spark-defaults.conf exists
if [ -f "$configurationFile" ]; then
  # Create EBCDIC version of spark-defaults.conf to be read by script.
  cp $configurationFile $configurationFileEBCDIC
  convertToEBCDIC $configurationFileEBCDIC

  # Read line by line of the temporary EBCDIC configuration file.
  while IFS='' read -r line || [[ -n "$line" ]]; do
    # If line isn't a comment and isn't blank
    if [[ ! "$line" =~ \#.* ]] && [[ ! -z "$line" ]];then
      # Split the line up in order to get the property and what it is set to.
      set -- $line

      # Add new property to SPARK_OPTS
      if [[ "$1" == "spark.master" ]]; then
        if [[ $SPARK_OPTS = "" ]]; then
          export SPARK_OPTS="--master=$2"
        else
          export SPARK_OPTS="--master=$2 $SPARK_OPTS"
        fi
      else
        if [[ $SPARK_OPTS = "" ]]; then
          export SPARK_OPTS="--conf $1=$2"
        else
          export SPARK_OPTS="$SPARK_OPTS --conf $1=$2"
        fi
      fi
    fi
  done < "$configurationFileEBCDIC"

  # Remove the temporary EBCDIC file.
  rm $configurationFileEBCDIC
fi

if [[ "${SPARK_OPTS}" != *"--master"* ]]; then
  if [[ $SPARK_LOCAL_IP = "" || $SPARK_MASTER_PORT = "" ]]; then
    echo "No master set. Toree will connect locally."
  else
    export SPARK_OPTS="--master=spark://$SPARK_LOCAL_IP:$SPARK_MASTER_PORT $SPARK_OPTS"
  fi
fi

echo "SPARK_OPTS has been configured for Apache Toree from Apache Spark configurations."
