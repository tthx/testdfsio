#!/bin/sh
unset CXXFLAGS;
export JAVA_HOME="/opt/jdk1.8.0_221";
export JAVA_OPTS="-XX:+UseG1GC";
export MAVEN_OPTS="${JAVA_OPTS} -Xms1g -Xmx1g";
export PATH="${JAVA_HOME}/bin:${PATH}";
mvn clean package;
