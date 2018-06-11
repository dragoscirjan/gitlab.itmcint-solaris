#! /bin/bash

which java || apt-get update && apt-get install -y openjdk-8-jdk openjdk-8-jre

[ -f /opt/jenkinks.war ] || curl -SL http://mirrors.jenkins.io/war/latest/jenkins.war > /opt/jenkins.war


JENKINS_HOME=${JENKINS_HOME:-/var/jenkins_home}


find /usr/share/jenkins/ref/ \( -type f -o -type l \) -exec bash -c '. /usr/local/bin/jenkins-support; for arg; do copy_reference_file "$arg"; done' _ {} +


USER=jenkins

[ -f /var/run/jenkins.pid ] && [ $(cat /var/run/jenkins.pid) != "" ] && kill -s 9 $(cat /var/run/jenkins.pid)

touch /var/run/jenkins.pid
chown $USER:$USER /var/run/jenkins.pid
su -s /bin/sh jenkins -c "
    cd /
    JENKINS_HOME=/var/lib/jenkins exec setsid /usr/bin/java   \
        -jar /usr/share/java/jenkins/jenkins.war          \
        $JENKINS_OPTS                                    \
    </dev/null >>/var/log/jenkins/console_log 2>&1 &
    echo \$! >/var/run/jenkins.pid
    disown \$!
    "