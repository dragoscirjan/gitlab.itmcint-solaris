#! /bin/bash
set -xe

HOSTNAME=$(hostname)
which java || apt-get update && apt-get install -y openjdk-8-jdk openjdk-8-jre

[ -f /opt/jenkins.txt ] && JENKINS_PORT=$((`cat /opt/jenkins.txt | ` + 1))

JENKINS_FOLDER=${JENKINS_FOLDER:-jenkins-`date '+%Y-%m-%d_%H%M%S'`}

mkdir -p /opt/$JENKINS_FOLDER
JENKINS_WAR=${JENKINS_WAR:-/opt/$JENKINS_FOLDER/jenkins.war}

JENKINS_PORT_OPTS=${JENKINS_PORT_OPTS:- --httpPort=$JENKINS_PORT}
JENKINS_OPTS=${JENKINS_OPTS:- }
JENKINS_SSL_PATH="/opt/jenkins.pfx"
JENKINS_USER=${JENKINS_USER:-jenkins}

cat /opt/jenkins.txt | grep -v JENKINS_PORT > /opt/jenkins.txt.new

rm /opt/jenkins.txt
mv /opt/jenkins.txt.new /opt/jenkins.txt

echo "JENKINS_PORT=$JENKINS_PORT" > /opt/jenkins.txt

export JENKINS_HOME=${JENKINS_HOME:-/var/lib/$JENKINS_FOLDER}
mkdir -p $JENKINS_HOME

JENKINS_LOG=${JENKINS_LOG:-/var/log/$JENKINS_FOLDER}
JENKINS_LOG_CLI=${JENKINS_LOG_CLI:-</dev/null >> /dev/null}
JENKINS_PID=${JENKINS_PID:-/var/run/jenkins.pid}

with_ssl() {
    [ $HOSTNAME == 'tiamat' ] && {
	    local LETSENCRYPT_PATH="/etc/letsencrypt/live/tiamat.itmcd.ro"
	    openssl pkcs12 -export -out $JENKINS_SSL_PATH -inkey $LETSENCRYPT_PATH/privkey.pem \
	        -in $LETSENCRYPT_PATH/cert.pem -certfile $LETSENCRYPT_PATH/chain.pem
    }
    [ $HOSTNAME == 'syrius' ] && {
	    local LETSENCRYPT_PATH="/etc/letsencrypt/live/itmcd.ro`"
	    openssl pkcs12 -export -out $JENKINS_SSL_PATH -inkey $LETSENCRYPT_PATH/privkey.pem \
	        -in $LETSENCRYPT_PATH/cert.pem -certfile $LETSENCRYPT_PATH/chain.pem
    }

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
    -c "exec setsid /usr/bin/java -jar $JENKINS_WAR $JENKINS_OPTS $JENKINS_LOG_CLI 2>&1 & \
echo \$! >$JENKINS_PID \
disown \$! \
"
