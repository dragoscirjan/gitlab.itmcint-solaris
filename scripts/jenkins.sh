#! /bin/bash
set -xe

HOSTNAME=$(hostname)
which java || apt-get update && apt-get install -y openjdk-8-jdk openjdk-8-jre

JENKINS_WAR=${JENKINS_WAR:-/opt/jenkins.war}
JENKINS_PORT_OPTS=${JENKINS_PORT_OPTS:- --httpPort=9321}
JENKINS_OPTS=${JENKINS_OPTS:- }
JENKINS_SSL_PATH="/opt/jenkins.pfx"
JENKINS_USER=${JENKINS_USER:-jenkins}

export JENKINS_HOME=${JENKINS_HOME:-/var/lib/jenkins}
JENKINS_LOG=${JENKINS_LOG:-/var/log/jenkins}
JENKINS_LOG_CLI=${JENKINS_LOG_CLI:-/dev/null}
JENKINS_PID=${JENKINS_PID:-/var/run/jenkins.pid}

with_ssl() {
    local LETSENCRYPT_PATH="/etc/letsencrypt/live/tiamat.itmcd.ro"
    [ $HOSTNAME == 'tiamat' ] && 
    openssl pkcs12 -export -out $JENKINS_SSL_PATH -inkey $LETSENCRYPT_PATH/privkey.pem -in $LETSENCRYPT_PATH/cert.pem -certfile $LETSENCRYPT_PATH/chain.pem

    JENKINS_PORT_OPTS=" --httpPort=-1 --httpsPort=9321"
    JENKINS_OPTS="$JENKINS_OPTS --httpsKeyStore=\"$JENKINS_SSL_PATH\" --httpsKeyStorePassword=\"jenkins\""
}

[ -f .ssl ] && with_ssl

# Add port options
JENKINS_OPTS="$JENKINS_OPTS $JENKINS_PORT_OPTS"

# Download war
[ -f $JENKINS_WAR ] || curl -SL http://mirrors.jenkins.io/war/latest/jenkins.war > $JENKINS_WAR

# Handle user
cat /etc/passwd | grep $JENKINS_USER || (
	groupadd -g 12345 $JENKINS_USER
	useradd -u 12345 -g $JENKINS_USER -s /bin/bash $JENKINS_USER
)
[ $JENKINS_USER != 'root' ] && mkdir -p /home/$JENKINS_USER && chown $JENKINS_USER:$JENKINS_USER /home/$JENKINS_USER
usermod -G $JENKINS_USER,docker $JENKINS_USER

# Process PID
touch $JENKINS_PID
chown $JENKINS_USER:$JENKINS_USER $JENKINS_PID

# Process Logs
mkdir -p $JENKINS_HOME $JENKINS_LOG
chown -R $JENKINS_USER:$JENKINS_USER $JENKINS_HOME $JENKINS_LOG

# Kill if needed
# [ -f $JENKINS_PID ] && [ "$(cat $JENKINS_PID)" != "" ] && kill -s 9 $(cat $JENKINS_PID)

# Run
su -s /bin/sh $JENKINS_USER \
    -c "exec setsid /usr/bin/java -jar $JENKINS_WAR $JENKINS_OPTS </dev/null >>$JENKINS_LOG_CLI 2>&1 & \
echo \$! >$JENKINS_PID \
disown \$! \
"
