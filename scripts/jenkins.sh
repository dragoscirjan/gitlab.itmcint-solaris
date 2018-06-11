#! /bin/bash

which java || apt-get update && apt-get install -y openjdk-8-jdk openjdk-8-jre

[ -f /opt/jenkinks.war ] || curl -SL http://mirrors.jenkins.io/war/latest/jenkins.war > /opt/jenkins.war

USER=${USER:-jenkins}

cat /etc/passwd | grep $USER || (
	groupadd -g 12345 $USER
	useradd -u 12345 -g $USER -s /bin/bash $USER
)

JENKINS_HOME=${JENKINS_HOME:-/var/lib/jenkins}

touch /var/run/jenkins.pid
chown $USER:$USER /var/run/jenkins.pid

[ -f /var/run/jenkins.pid ] && [ "$(cat /var/run/jenkins.pid)" != "" ] && kill -s 9 $(cat /var/run/jenkins.pid)

su -s /bin/sh jenkins -c "\
    exec setsid /usr/bin/java -jar /opt/jenkins.war \
		$JENKINS_OPTS \
    </dev/null >> /var/log/jenkins/console_log 2>&1 & \
    echo \$! >/var/run/jenkins.pid \
    disown \$! \
"