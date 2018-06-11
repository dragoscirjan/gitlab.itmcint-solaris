#! /bin/bash
set -xe

which java || apt-get update && apt-get install -y openjdk-8-jdk openjdk-8-jre

JENKINS_WAR=${JENKINS_WAR:-/opt/jenkins.war}

[ -f $JENKINS_WAR ] || curl -SL http://mirrors.jenkins.io/war/latest/jenkins.war > $JENKINS_WAR

JENKINS_USER=${JENKINS_USER:-jenkins}

cat /etc/passwd | grep $JENKINS_USER || (
	groupadd -g 12345 $JENKINS_USER
	useradd -u 12345 -g $JENKINS_USER -s /bin/bash $JENKINS_USER
)

JENKINS_HOME=${JENKINS_HOME:-/var/lib/jenkins}
JENKINS_LOG=${JENKINS_LOG:-/var/log/jenkins}
JENKINS_PID=${JENKINS_PID:-/var/run/jenkins.pid}

touch $JENKINS_PID
chown $JENKINS_USER:$JENKINS_USER $JENKINS_PID

mkdir -p $JENKINS_HOME $JENKINS_LOG
chown -R $JENKINS_USER:$JENKINS_USER $JENKINS_HOME $JENKINS_LOG

# [ -f $JENKINS_PID ] && [ "$(cat $JENKINS_PID)" != "" ] && kill -s 9 $(cat $JENKINS_PID)

su -s /bin/sh jenkins \
    -c "exec setsid /usr/bin/java -jar $JENKINS_WAR $JENKINS_OPTS </dev/null >> $JENKINS_LOG/console_log 2>&1 & \
echo \$! > $JENKINS_PID; \
disown \$!"