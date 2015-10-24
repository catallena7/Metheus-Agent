#!/bin/bash

JAVA_HOME="/opt/jdk1.8.0_51"
AGENT_HOME="/home/catallena7"
JAR_NAME="MAgent.jar"
CONF_FILE="${AGENT_HOME}/config.xml"

agentPIDs=`ps -ef |grep java |grep jar |grep  ${JAR_NAME} |grep -v grep| awk '{print $2}'`

if [ "$agentPIDs" ] ; then
	echo "Agent is already running"
	echo $agentPIDs
else
	cd $AGENT_HOME
	cwd=`pwd`
	if [ $cwd == $AGENT_HOME ] && [ -f $CONF_FILE ] ; then
		${JAVA_HOME}/bin/java -jar ${AGENT_HOME}/${JAR_NAME} ${CONF_FILE}
		echo "RUN Agent at $cwd"
	else
		echo "Something is wrong. Please check your directory or configuration file"
	fi
fi
	
