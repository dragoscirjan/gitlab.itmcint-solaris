#! /bin/bash

which java || apt-get update && apt-get install -y openjdk-8-jdk openjdk-8-jre

JENKINS_WAR=${JENKINS_WAR:-/opt/jenkins.war}

[ -f $JENKINS_WAR ] || curl -SL http://mirrors.jenkins.io/war/latest/jenkins.war > $JENKINS_WAR

USER=${USER:-jenkins}

cat /etc/passwd | grep $USER || (
	groupadd -g 12345 $USER
	useradd -u 12345 -g $USER -s /bin/bash $USER
)

JENKINS_HOME=${JENKINS_HOME:-/var/lib/jenkins}
JENKINS_PID=${JENKINS_PID:-/var/run/jenkins.pid}

touch $JENKINS_PID
chown $USER:$USER $JENKINS_PID

mkdir -p $JENKINS_HOME
chown -R $USER:$USER $JENKINS_HOME

[ -f $JENKINS_PID ] && [ "$(cat $JENKINS_PID)" != "" ] && kill -s 9 $(cat $JENKINS_PID)

su -s /bin/sh jenkins -c "\
    exec setsid /usr/bin/java -jar $JENKINS_WAR \
		$JENKINS_OPTS \
    </dev/null >> /var/log/jenkins/console_log 2>&1 & \
    echo \$! >$JENKINS_PID \
    disown \$! \
"