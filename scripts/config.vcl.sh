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
backend web1 {
VCL_CONFIG

count=0
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
    $(docker ps -a | grep global_nginx\. | cut -f1 -d' ') \
    | while read hostip; do

        echo "    .host = "$hostip"; # template";
        count=$((count + 1))
done

cat <<VCL_CONFIG
    .host = "127.0.0.1"; # static
#    .probe = { .url = "/status.php"; .interval = 5s; .timeout = 1s; .window = 5;.threshold = 3; }
}

#backend web2 { .host = "192.10.0.2"; .probe = { .url = "/status.php"; .interval = 5s; .timeout = 1s; .window = 5;.threshold = 3; }}

# Port 443 Backend Servers for SSL
# backend web1_ssl { 
#     .host = "192.10.0.1"; 
#     .port = "443"; 
#     .probe = { .url = "/status.php"; .interval = 5s; .timeout = 1 s; .window = 5;.threshold = 3; }
# }
# backend web2_ssl { .host = "192.10.0.2"; .port = "443"; .probe = { .url = "/status.php"; .interval = 5s; .timeout = 1 s; .window = 5;.threshold = 3; }}

# Define the director that determines how to distribute incoming requests.
director default_director round-robin {
#    { .backend = web1; }
VCL_CONFIG

for i in 1..$count; do
    echo "  { .backend = web$i; }"
done

cat <<VCL_CONFIG
#  { .backend = web2; }
}
VCL_CONFIG

cat $HERE/config.vcl