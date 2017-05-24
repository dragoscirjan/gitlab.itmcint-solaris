#! /bin/sh
set -e

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

# @link https://www.google.ro/search?q=varnish+cache+multiple+source&oq=varnish+cache+multiple+source&aqs=chrome..69i57.17976j0j4&client=ubuntu&sourceid=chrome&ie=UTF-8#q=varnish+cache+multiple+sources
#
# @link https://varnish-cache.org/
# @link https://www.lullabot.com/articles/configuring-varnish-for-highavailability-with-multiple-web-servers

cat <<VCL_CONFIG
# Define the list of backends (web servers).
# Port 80 Backend Servers
VCL_CONFIG

hosts=`docker inspect --format='{{.Name}}-{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -a | grep global_nginx\. | cut -f1 -d' ')`;
hosts_count=$(echo $hosts | wc -l);
i=1;

echo $hosts | while read hostip; do

	cat <<VCL_CONFIG
backend web$i {
    .host = "$(echo $hostip | cut -f2 -d'-')"; # $(echo $hostip | cut -f1 -d'-') template
    # .probe = { .url = "/status.php"; .interval = 5s; .timeout = 1s; .window = 5;.threshold = 3; }
}
VCL_CONFIG
	i=$((i+1))

done

cat <<VCL_CONFIG

# $hosts_count hosts discovered

# Define the director that determines how to distribute incoming requests.
director default_director round-robin {
VCL_CONFIG

for (( i=1 ; i<=$hosts_count; i++ )); do
    echo "  { .backend = web$i; }"
done

cat <<VCL_CONFIG
}
VCL_CONFIG

cat $HERE/config.vcl
