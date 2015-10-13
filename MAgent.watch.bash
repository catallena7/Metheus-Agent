#!/bin/bash

JAVA_HOME="/opt/jdk1.8.0_51"
AGENT_HOME="/home/catallena7/workspace-luna-client/Metheus-Agent"
PS_NAME="MAgent.jar"
CONF_FILE="${AGENT_HOME}/configure.ini

agentPIDs=`ps -ef |grep java |grep jar |grep  ${PS_NAME} |grep -v grep| awk '{print $2}'`

if [ "$agentPIDs" ] ; then
	echo "Agent is already running
	echo $agentPIDs
else
	cd $AGENT_HOME
	cwd=`pwd`
	if [ $cwd == $AGENT_HOME ] && [ -f $CONF_FILE ] ; then
		${JAVA_HOME}/bin/java -jar ${AGENT_HOME}/MAgent.jar ${CONF_FILE}
		echo "RUN Agent at $cwd"
	else
		echo "Something is wrong. Please check your directory or configuration file"
		echo "conf=$CONF_FILE"
		echo "home=$AGENT_HOME"
	fi
fi
	
