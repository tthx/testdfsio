#!/bin/bash

nil="nil";

TEST_BUILD_DATA_PROP="test.build.data";
TEST_BUILD_DATA="";
RESULT_DIR_PROP="resultDir";
RESULT_DIR="";
RESULT_FILE_PROP="resFile";
RESULT_FILE_PREFIX="TestDFSIO";
WRITE_OCCURENCE_PROP="nrOcc.write";
WRITE_OCCURENCE="";
READ_OCCURENCE_PROP="nrOcc.read";
READ_OCCURENCE="";
NRFILES_PROP="nrFiles";
NRFILES_LIST="";
SIZE_PROP="size";
SIZE_LIST="";
BUFFER_SIZE_PROP="bufferSize";
BUFFER_SIZE_LIST="4096";
BLOCK_SIZE_PROP="dfs.blocksize";
BLOCK_SIZE_LIST="256m";
REPLICATION_PROP="dfs.replication";
REPLICATION_LIST="3";
COMPRESSION_PROP="compression";
COMPRESSION_LIST="${nil}";
STORAGE_POLICY_PROP="storagePolicy";
STORAGE_POLICY_LIST="${nil}";
ERASURE_CODE_POLICY_PROP="erasureCodePolicy";
ERASURE_CODE_POLICY_LIST="${nil}";
SHORT_CIRCUIT_PROP="shortcircuit";
SHORT_CIRCUIT="";
WRITE_PROP="write";
READ_PROP="read";

JAR_FILE_PROP="jarFile";
JAR_FILE="TestDFSIO-0.0.1.jar";
PROGRAM="com.orange.tgi.ols.arsec.paas.aacm.benchmarks.TestDFSIO";

JAVA_HOME_PROP="java.home";
JAVA_OPTS_PROP="java.opts";
JAVA_CMD="java";

HADOOP_HOME_PROP="hadoop.home";
HADOOP_CONF_DIR_PROP="hadoop.conf.dir";
YARN_CMD="yarn";

YARN_APP_MAPREDUCE_AM_LOG_LEVEL_PROP="yarn.app.mapreduce.am.log.level";
YARN_APP_MAPREDUCE_AM_LOG_LEVEL="INFO";
# Map tasks properties
MAPREDUCE_JOB_MAPS_PROP="mapreduce.job.maps";
MAPREDUCE_JOB_MAPS="2";
MAPREDUCE_JOB_RUNNING_MAP_LIMIT_PROP="mapreduce.job.running.map.limit";
MAPREDUCE_JOB_RUNNING_MAP_LIMIT="0";
MAPREDUCE_MAP_MEMORY_MB_PROP="mapreduce.map.memory.mb";
MAPREDUCE_MAP_MEMORY_MB="1024";
MAPREDUCE_MAP_JAVA_OPTS_PROP="mapreduce.map.java.opts";
MAPREDUCE_MAP_JAVA_OPTS="-XX:+UseG1GC";
MAPREDUCE_MAP_LOG_LEVEL_PROP="mapreduce.map.log.level";
MAPREDUCE_MAP_LOG_LEVEL="INFO";
# Reducer tasks properties
MAPREDUCE_JOB_REDUCES_PROP="mapreduce.job.reduces";
MAPREDUCE_JOB_REDUCES="1";
MAPREDUCE_JOB_RUNNING_REDUCE_LIMIT_PROP="mapreduce.job.running.reduce.limit";
MAPREDUCE_JOB_RUNNING_REDUCE_LIMIT="0";
MAPREDUCE_REDUCE_MEMORY_MB_PROP="mapreduce.reduce.memory.mb";
MAPREDUCE_REDUCE_MEMORY_MB="1024";
MAPREDUCE_REDUCE_JAVA_OPTS_PROP="mapreduce.reduce.java.opts";
MAPREDUCE_REDUCE_JAVA_OPTS="-XX:+UseG1GC";
MAPREDUCE_REDUCE_LOG_LEVEL_PROP="mapreduce.reduce.log.level";
MAPREDUCE_REDUCE_LOG_LEVEL="INFO";

function echoerr { printf "%s\n" "${@}" >&2; }

function countWord { printf "%s" ${#}; }

function trim() {
  local var="${*}";
  # remove leading whitespace characters
  var="${var#"${var%%[![:space:]]*}"}";
  # remove trailing whitespace characters
  var="${var%"${var##*[![:space:]]}"}";
  printf "%s" "${var}";
}

function getProperties {
  local errmsg="ERROR: ${FUNCNAME[0]}:";
  local propertiesFile="${1:?"${errmsg} Missing properties file"}";
  local line;
  local key;
  local value;
  if [[ ! -f "${propertiesFile}" ]];
  then
    echoerr "${errmsg} File \"${propertiesFile}\" was not found.";
    return 1;
  fi
  line=0;
  while IFS='=' read -r key value;
  do
    line=$((line+1));
    if [[ ! "${key}" =~ ^[[:space:]]*#+(.*)?$ ]] && [[ -n "${key}" ]];
    then
      if [[ -z "${value}" ]];
      then
        echoerr "${errmsg} Key \"${key}\" at line \"${line}\" in file \"${propertiesFile}\" has no value.";
        return 1;
      fi
      key="$(trim "${key}")";
      value="${value%%#*}";
      value="$(trim "${value}")";
      case "${key,,}" in
        "${COMPRESSION_PROP,,}")
          COMPRESSION_LIST+=" ${value}";
          ;;
        "${STORAGE_POLICY_PROP,,}")
          STORAGE_POLICY_LIST+=" ${value}";
          ;;
        "${ERASURE_CODE_POLICY_PROP,,}")
          ERASURE_CODE_POLICY_LIST+=" ${value}";
          ;;
        "${SHORT_CIRCUIT_PROP,,}")
          if [[ "${value,,}" =~ ^[[:space:]]*true[[:space:]]*$ ]] || \
            [[ ${value} -eq 1 ]];
          then
            SHORT_CIRCUIT="${value}";
          fi
          ;;
        "${WRITE_OCCURENCE_PROP,,}")
          WRITE_OCCURENCE="${value}";
          ;;
        "${READ_OCCURENCE_PROP,,}")
          READ_OCCURENCE="${value}";
          ;;
        "${TEST_BUILD_DATA_PROP,,}")
          TEST_BUILD_DATA="${value}";
          ;;
        "${BUFFER_SIZE_PROP,,}")
          BUFFER_SIZE_LIST="${value}";
          ;;
        "${NRFILES_PROP,,}")
          NRFILES_LIST="${value}";
          ;;
        "${SIZE_PROP,,}")
          SIZE_LIST="${value}";
          ;;
        "${BLOCK_SIZE_PROP,,}")
          BLOCK_SIZE_LIST="${value}";
          ;;
        "${REPLICATION_PROP,,}")
          REPLICATION_LIST="${value}";
          ;;
        "${RESULT_DIR_PROP,,}")
          RESULT_DIR="${value}";
          ;;
        "${JAR_FILE_PROP,,}")
          JAR_FILE="${value}";
          ;;
        "${JAVA_HOME_PROP,,}")
          export JAVA_HOME="${value}";
          export PATH="${JAVA_HOME}/bin:${PATH}";
          ;;
        "${JAVA_OPTS_PROP,,}")
          export JAVA_OPTS="${value}";
          ;;
        "${HADOOP_HOME_PROP,,}")
          export HADOOP_HOME="${value}";
          export PATH="${HADOOP_HOME}/bin:${PATH}";
          export HADOOP_COMMON_LIB_NATIVE_DIR="${HADOOP_HOME}/lib/native";
          if [[ -n "${LD_LIBRARY_PATH}" ]];
          then
            export LD_LIBRARY_PATH+=":${HADOOP_COMMON_LIB_NATIVE_DIR}";
          else
            export LD_LIBRARY_PATH="${HADOOP_COMMON_LIB_NATIVE_DIR}";
          fi
          ;;
        "${HADOOP_CONF_DIR_PROP,,}")
          export HADOOP_CONF_DIR="${value}";
          ;;
        "${YARN_APP_MAPREDUCE_AM_LOG_LEVEL_PROP,,}")
          YARN_APP_MAPREDUCE_AM_LOG_LEVEL="${value}";
          ;;
        "${MAPREDUCE_JOB_MAPS_PROP,,}")
          MAPREDUCE_JOB_MAPS="${value}";
          ;;
        "${MAPREDUCE_JOB_RUNNING_MAP_LIMIT_PROP,,}")
          MAPREDUCE_JOB_RUNNING_MAP_LIMIT="${value}";
          ;;
        "${MAPREDUCE_MAP_MEMORY_MB_PROP,,}")
          MAPREDUCE_MAP_MEMORY_MB="${value}";
          ;;
        "${MAPREDUCE_MAP_JAVA_OPTS_PROP,,}")
          MAPREDUCE_MAP_JAVA_OPTS="${value}";
          ;;
        "${MAPREDUCE_MAP_LOG_LEVEL_PROP,,}")
          MAPREDUCE_MAP_LOG_LEVEL="${value}";
          ;;
        "${MAPREDUCE_JOB_REDUCES_PROP,,}")
          MAPREDUCE_JOB_REDUCES="${value}";
          ;;
        "${MAPREDUCE_JOB_RUNNING_REDUCE_LIMIT_PROP,,}")
          MAPREDUCE_JOB_RUNNING_REDUCE_LIMIT="${value}";
          ;;
        "${MAPREDUCE_REDUCE_MEMORY_MB_PROP,,}")
          MAPREDUCE_REDUCE_MEMORY_MB="${value}";
          ;;
        "${MAPREDUCE_REDUCE_JAVA_OPTS_PROP,,}")
          MAPREDUCE_REDUCE_JAVA_OPTS="${value}";
          ;;
        "${MAPREDUCE_MAP_LOG_LEVEL_PROP}")
          MAPREDUCE_MAP_LOG_LEVEL="${value}";
          ;;
        *)
          echoerr "${errmsg} Unknown key \"${key}\" at line \"${line}\" in properties file \"${propertiesFile}\"";
          return 1;
          ;;
      esac
    fi
  done < "${propertiesFile}"
  return 0;
}

function checkRequirements {
  local errmsg="ERROR: ${FUNCNAME[0]}:";
  local err;
  if [[ -z "$(command -v ${JAVA_CMD})" ]];
  then
    echoerr "${errmsg} \"${JAVA_CMD}\" command is not found in PATH";
    return 1;
  fi
  if [[ -z "$(command -v ${YARN_CMD})" ]];
  then
    echoerr "${errmsg} \"${YARN_CMD}\" command is not found in PATH";
    return 1;
  fi
  if [[ ! -f "${JAR_FILE}" ]];
  then
    echoerr "${errmsg} File \"${JAR_FILE}\" is not found.";
    return 1;
  fi
  if [[ -z "${WRITE_OCCURENCE}" ]];
  then
    echoerr "${errmsg} \"${WRITE_OCCURENCE_PROP}\" property is not defined";
    return 1;
  fi
  if [[ -z "${READ_OCCURENCE}" ]];
  then
    echoerr "${errmsg} \"${READ_OCCURENCE_PROP}\" property is not defined";
    return 1;
  fi
  if [[ -z "${TEST_BUILD_DATA}" ]];
  then
    echoerr "${errmsg} \"${TEST_BUILD_DATA_PROP}\" property is not defined";
    return 1;
  fi
  if [[ -z "${NRFILES_LIST}" ]];
  then
    echoerr "${errmsg} \"${NRFILES_PROP}\" property is not defined";
    return 1;
  fi
  if [[ -z "${SIZE_LIST}" ]];
  then
    echoerr "${errmsg} \"${SIZE_PROP}\" property is not defined";
    return 1;
  fi
  if [[ -z "${RESULT_DIR}" ]];
  then
    echoerr "${errmsg} \"${RESULT_DIR_PROP}\" property is not defined";
    return 1;
  else
    if [[ ! -d "${RESULT_DIR}" ]];
    then
      err="$(mkdir -p "${RESULT_DIR}" 2>&1)";
      if [[ ! ${?} -eq 0 ]];
      then
        echoerr "${errmsg} Unable to create directory \"${RESULT_DIR}\": ${err}";
        return 1;
      fi
    fi
  fi
  return 0;
}

function main {
  getProperties "${1}";
  if [[ ! ${?} -eq 0 ]];
  then
    return 1;
  fi
  checkRequirements;
  if [[ ! ${?} -eq 0 ]];
  then
    return 1;
  fi
  local errmsg="ERROR: ${FUNCNAME[0]}:";
  local err;
  local base_cmd;
  local cmd;
  local result_file;
  local operation;
  local iOcc_write;
  local iOcc_read;
  local nrOcc;
  local iOcc;
  local iFile;
  local iSize;
  local iBuffer;
  local iBlock;
  local iReplication;
  local iStorage;
  local iErasureCode;
  local iCompression;
  local iOp;
  local parameters;
  base_cmd="${YARN_CMD} jar ${JAR_FILE} ${PROGRAM} \
    -D${YARN_APP_MAPREDUCE_AM_LOG_LEVEL_PROP}=${YARN_APP_MAPREDUCE_AM_LOG_LEVEL} \
    -D${MAPREDUCE_JOB_MAPS_PROP}=${MAPREDUCE_JOB_MAPS} \
    -D${MAPREDUCE_JOB_RUNNING_MAP_LIMIT_PROP}=${MAPREDUCE_JOB_RUNNING_MAP_LIMIT} \
    -D${MAPREDUCE_MAP_MEMORY_MB_PROP}=${MAPREDUCE_MAP_MEMORY_MB} \
    -D${MAPREDUCE_MAP_JAVA_OPTS_PROP}=${MAPREDUCE_MAP_JAVA_OPTS} \
    -D${MAPREDUCE_MAP_LOG_LEVEL_PROP}=${MAPREDUCE_MAP_LOG_LEVEL} \
    -D${MAPREDUCE_JOB_REDUCES_PROP}=${MAPREDUCE_JOB_REDUCES} \
    -D${MAPREDUCE_JOB_RUNNING_REDUCE_LIMIT_PROP}=${MAPREDUCE_JOB_RUNNING_REDUCE_LIMIT} \
    -D${MAPREDUCE_REDUCE_MEMORY_MB_PROP}=${MAPREDUCE_REDUCE_MEMORY_MB} \
    -D${MAPREDUCE_REDUCE_JAVA_OPTS_PROP}=${MAPREDUCE_REDUCE_JAVA_OPTS} \
    -D${MAPREDUCE_REDUCE_LOG_LEVEL_PROP}=${MAPREDUCE_REDUCE_LOG_LEVEL} \
    -D${TEST_BUILD_DATA_PROP}=${TEST_BUILD_DATA}";
  operation="${WRITE_PROP} ${READ_PROP}";
  iOcc_write=0;
  nrOcc=$(($(countWord ${STORAGE_POLICY_LIST})* \
    $(countWord ${ERASURE_CODE_POLICY_LIST})* \
    $(countWord ${BUFFER_SIZE_LIST})* \
    $(countWord ${NRFILES_LIST})* \
    $(countWord ${SIZE_LIST})* \
    $(countWord ${BLOCK_SIZE_LIST})* \
    $(countWord ${REPLICATION_LIST})* \
    WRITE_OCCURENCE));
  iOcc=0;
  if [[ -n "${SHORT_CIRCUIT}" ]];
  then
    iOcc=$((nrOcc*READ_OCCURENCE));
  fi
  nrOcc=$(((nrOcc*$(countWord ${COMPRESSION_LIST})*READ_OCCURENCE)+iOcc));
  iOcc=1;
  while [[ ${iOcc_write} -lt ${WRITE_OCCURENCE} ]];
  do
    for iBlock in ${BLOCK_SIZE_LIST};
    do
      for iReplication in ${REPLICATION_LIST};
      do
        for iFile in ${NRFILES_LIST};
        do
          for iSize in ${SIZE_LIST};
          do
            for iBuffer in ${BUFFER_SIZE_LIST};
            do
              for iStorage in ${STORAGE_POLICY_LIST};
              do
                for iCompression in ${COMPRESSION_LIST};
                do
                  for iErasureCode in ${ERASURE_CODE_POLICY_LIST};
                  do
                    for iOp in ${operation};
                    do
                      cmd="${base_cmd} \
                        -D${BLOCK_SIZE_PROP}=${iBlock} \
                        -D${REPLICATION_PROP}=${iReplication} \
                        -${NRFILES_PROP} ${iFile} \
                        -${SIZE_PROP} ${iSize} \
                        -${BUFFER_SIZE_PROP} ${iBuffer}";
                      result_file="-${RESULT_FILE_PROP} \
                        ${RESULT_DIR}/${RESULT_FILE_PREFIX}-${BLOCK_SIZE_PROP}=${iBlock}-${REPLICATION_PROP}=${iReplication}-${NRFILES_PROP}=${iFile}-${SIZE_PROP}=${iSize}-${BUFFER_SIZE_PROP}=${iBuffer}";
                      parameters="blk:${iBlock},rep:${iReplication},nrf:${iFile},size:${iSize},buf:${iBuffer},stopol:${iStorage},zip:${iCompression},ec:${iErasureCode}";
                      if [[ "${iStorage}" != "${nil}" ]];
                      then
                        cmd+=" -${STORAGE_POLICY_PROP} ${iStorage}";
                        result_file+="-${STORAGE_POLICY_PROP}=${iStorage}";
                      fi
                      if [[ "${iCompression}" != "${nil}" ]];
                      then
                        cmd+=" -${COMPRESSION_PROP} ${iCompression}";
                        result_file+="-${COMPRESSION_PROP}=${iCompression}";
                      fi
                      if [[ "${iErasureCode}" != "${nil}" ]];
                      then
                        cmd+=" -${ERASURE_CODE_POLICY_PROP} ${iErasureCode}";
                        result_file+="-${ERASURE_CODE_POLICY_PROP}=${iErasureCode}";
                      fi
                      cmd+=" -${iOp}";
                      result_file+="-${iOp}";
                      case "${iOp}" in
                        "${WRITE_PROP}")
                          echo "Progression: ${iOcc}/${nrOcc}: ${iOp},${parameters}";
                          iOcc=$((iOcc+1));
                          err="$(${cmd} ${result_file}.log 2>&1)";
                          if [[ ! ${?} -eq 0 ]];
                          then
                            echoerr "${errmsg} ${err}";
                            return 1;
                          fi
                          ;;
                        "${READ_PROP}")
                          iOcc_read=0;
                          while [[ ${iOcc_read} -lt ${READ_OCCURENCE} ]];
                          do
                            echo "Progression: ${iOcc}/${nrOcc}: ${iOp},${parameters}";
                            iOcc=$((iOcc+1));
                            err="$(${cmd} ${result_file}.log 2>&1)";
                            if [[ ! ${?} -eq 0 ]];
                            then
                              echoerr "${errmsg} ${err}";
                              return 1;
                            fi
                            iOcc_read=$((iOcc_read+1));
                          done
                          if [[ -n "${SHORT_CIRCUIT}" ]] && \
                            [[ "${iCompression}" == "${nil}" ]];
                          then
                            cmd+=" -${SHORT_CIRCUIT_PROP}";
                            result_file+="-${SHORT_CIRCUIT_PROP}";
                            iOcc_read=0;
                            while [[ ${iOcc_read} -lt ${READ_OCCURENCE} ]];
                            do
                              echo "Progression: ${iOcc}/${nrOcc}: ${iOp},short,${parameters}";
                              iOcc=$((iOcc+1));
                              err="$(${cmd} ${result_file}.log 2>&1)";
                              if [[ ! ${?} -eq 0 ]];
                              then
                                echoerr "${errmsg} ${err}";
                                return 1;
                              fi
                              iOcc_read=$((iOcc_read+1));
                            done
                          fi
                          ;;
                      esac
                    done
                  done
                done
              done
            done
          done
        done
      done
    done
    iOcc_write=$((iOcc_write+1));
  done
  return 0;
}

main "${@}";
exit ${?};
