#! /bin/bash

IP="127.0.0.1"
[ "$1" != "" ] && IP="$1"

echo "----------------------------------------"
echo "."
echo "FOR: ${IP}"
echo "."
echo "----------------------------------------"

while [ true ]; do
  curl -v http://${IP}:8080/dashboard &>/dev/null
  exitcode=$?
  if [ "$exitcode" == "0" ]; then
    echo "----------------------------------------"
    echo "."
    echo "ECLIPSE CHE: SERVER BOOTED AND REACHABLE"
    echo "AVAILABLE: http://${IP}:8080  "
    echo "."
    echo "----------------------------------------"
    break
  fi
  # If we are not awake after 60 seconds, restart server
  if [ "$counter" == "11" ]; then
    echo "-----------------------------------------------"
    echo "."
    echo "ECLIPSE CHE: SERVER NOT RESPONSIVE -- REBOOTING"
    echo "."
    echo "-----------------------------------------------"
    export JAVA_HOME=/usr/lib/jvm/java-8-oracle
    if [ "`whoami`" == "root" ]; then
      sudo -S -E -u vagrant /home/vagrant/eclipse-che-latest/nightly*/bin/che.sh --remote:${IP} --skip:client -g start &>/dev/null
    else
      $(pwd)/eclipse-che-latest/eclipse*/bin/che.sh --remote:${IP} --skip:client -g start #&>/dev/null
    fi
  fi
  # If we are not awake after 180 seconds, exit with failure
  if [ "$counter" == "35" ]; then
    echo "---------------------------------------------"
    echo "."
    echo "ECLIPSE CHE: SERVER NOT RESPONSIVE -- EXITING"
    echo "           CONTACT SUPPORT FOR ASSISTANCE    "
    echo "."
    echo "---------------------------------------------"
    break
  fi
  let counter=counter+1
  sleep 5
  echo ...$counter
done

docker ps
