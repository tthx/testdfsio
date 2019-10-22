!#!bin/bash

BUFFER_SIZE_LIST="";
NRFILES_LIST="";
SIZE_LIST="";
BLOCK_SIZE_LIST="";
REPLICATION_LIST="";
RESULT_DIR="";

JAR_FILE="TestDFSIO-0.0.1.jar";

YARN_APP_MAPREDUCE_AM_LOG_LEVEL="INFO";
MAPREDUCE_JOB_MAPS="2";
MAPREDUCE_JOB_RUNNING_MAP_LIMIT="0";
MAPREDUCE_MAP_MEMORY_MB="1g";
MAPREDUCE_MAP_JAVA_OPTS="-XX:+UseG1GC";
MAPREDUCE_MAP_LOG_LEVEL="INFO";
MAPREDUCE_JOB_REDUCES="1";
MAPREDUCE_JOB_RUNNING_REDUCE_LIMIT="0";
MAPREDUCE_REDUCE_MEMORY_MB="1g";
MAPREDUCE_REDUCE_JAVA_OPTS="-XX:+UseG1GC";
MAPREDUCE_MAP_LOG_LEVEL="INFO";

function echoerr { printf "%s\n" "${@}" >&2; }

function getProperties {
  local errmsg="ERROR: ${FUNCNAME[0]}:";
  local propertiesFile="${1:?"${errmsg} Missing properties file"}";
  local line;
  local key;
  local value;
  local bufferSizeList="";
  local fileList="";
  local sizeList="";
  local blockSizeList="";
  local replicationList="";
  if [[ ! -f "${propertiesFile}" ]];
  then
    echoerr "${errmsg} File \"${propertiesFile}\" was not found.";
    return 1;
  fi
  line=0;
  while IFS='=' read -r key value;
  do
    line=$((${line}+1));
    if [[ ! "${key}" =~ ^[[:space:]]*#+(.*)?$ ]] && [[ -n "${key}" ]];
    then
      if [[ -z "${value}" ]];
      then
        echoerr "${errmsg} Key \"${key}\" at line \"${line}\" in file \"${propertiesFile}\" has no value.";
        return 1;
      fi
      key="${key//[[:space:]]/}";
      value="${value%%#*}";
      case "${key}" in
        bufferSize)
          BUFFER_SIZE_LIST="${value}";
          ;;
        nrFiles)
          NRFILES_LIST="${value}";
          ;;
        size)
          SIZE_LIST="${value}";
          ;;
        blockSize)
          BLOCK_SIZE_LIST="${value}";
          ;;
        replication)
          REPLICATION_LIST="${value}";
          ;;
        resultDir)
          RESULT_DIR="${value}";
          ;;
        jarFile)
          JAR_FILE="${value}";
          ;;
        java\.home)
          export JAVA_HOME="${value}";
          export PATH="${JAVA_HOME}/bin:${PATH}";
          ;;
        java\.opts)
          export JAVA_OPTS="${value}";
          ;;
        hadoop\.home)
          export HADOOP_HOME="${value}";
          export PATH="${HADOOP_HOME}/bin:${PATH}";
          ;;
        hadoop.conf.dir)
          export HADOOP_CONF_DIR="${value}";
          ;;
        yarn\.app\.mapreduce\.am\.log\.level)
          YARN_APP_MAPREDUCE_AM_LOG_LEVEL="${value}";
          ;;
        mapreduce\.job\.maps)
          MAPREDUCE_JOB_MAPS="${value}";
          ;;
        mapreduce\.job\.running\.map\.limit)
          MAPREDUCE_JOB_RUNNING_MAP_LIMIT="${value}";
          ;;
        mapreduce\.map\.memory\.mb)
          MAPREDUCE_MAP_MEMORY_MB="${value}";
          ;;
        mapreduce\.map\.java\.opts)
          MAPREDUCE_MAP_JAVA_OPTS="${value}";
          ;;
        mapreduce\.map\.log\.level)
          MAPREDUCE_MAP_LOG_LEVEL="${value}";
          ;;
        mapreduce\.job\.reduces)
          MAPREDUCE_JOB_REDUCES="${value}";
          ;;
        mapreduce\.job\.running\.reduce\.limit)
          MAPREDUCE_JOB_RUNNING_REDUCE_LIMIT="${value}";
          ;;
        mapreduce\.reduce\.memory\.mb)
          MAPREDUCE_REDUCE_MEMORY_MB="${value}";
          ;;
        mapreduce\.reduce\.java\.opts)
          MAPREDUCE_REDUCE_JAVA_OPTS="${value}";
          ;;
        mapreduce\.reduce\.log\.level)
          MAPREDUCE_MAP_LOG_LEVEL="${value}";
          ;;
      esac
    fi
  done < "${propertiesFile}"
  return 0;
}

function checkRequirements {
  local errmsg="ERROR: ${FUNCNAME[0]}:";
  if [[ -z "$(which java)" ]];
  then
    echoerr "${errmsg} \"java\" command is not found in PATH";
    return 1;
  fi
  if [[ -z "$(which yarn)" ]];
  then
    echoerr "${errmsg} \"yarn\" command is not found in PATH";
    return 1;
  fi
  if [[ ! -f "${JAR_FILE}" ]];
  then
    echoerr "${errmsg} File \"${JAR_FILE}\" is not found.";
    return 1;
  fi
  if [[ -z "${BUFFER_SIZE_LIST}" ]];
  then
    echoerr "${errmsg} \"bufferSize\" property is not defined";
    return 1;
  fi
  if [[ -z "${NRFILES_LIST}" ]];
  then
    echoerr "${errmsg} \"nrFiles\" property is not defined";
    return 1;
  fi
  if [[ -z "${SIZE_LIST}" ]];
  then
    echoerr "${errmsg} \"size\" property is not defined";
    return 1;
  fi
  if [[ -z "${BLOCK_SIZE_LIST}" ]];
  then
    echoerr "${errmsg} \"blockSize\" property is not defined";
    return 1;
  fi
  if [[ -z "${REPLICATION_LIST}" ]];
  then
    echoerr "${errmsg} \"replication\" property is not defined";
    return 1;
  fi
  if [[ -z "${RESULT_DIR}" ]];
  then
    echoerr "${errmsg} \"resultDir\" property is not defined";
    return 1;
  else
    if [[ ! -d "${RESULT_DIR}" ]];
    then
      mkdir -p "${RESULT_DIR}";
      if [[ ! ${?} -eq 0 ]];
      then
        echoerr "${errmsg} Unable to create directory \"${RESULT_DIR}\"";
        return 1;
      fi
    fi
  fi
  return 0;
}