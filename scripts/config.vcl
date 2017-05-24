# # Define the list of backends (web servers).

# # Port 80 Backend Servers
# backend web1 { 
# 	.host = "192.10.0.1"; 
# 	.probe = { 
# 		.url = "/status.php"; 
# 		.interval = 5s; 
# 		.timeout = 1s; 
# 		.window = 5;
# 		.threshold = 3;
# 	}
# }
# # backend web2 { ... }

# # Port 443 Backend Servers for SSL
# backend web1_ssl { 
# 	.host = "192.10.0.1"; 
# 	.port = "443"; 
# 	.probe = { 
# 		.url = "/status.php"; 
# 		.interval = 5s; 
# 		.timeout = 1 s; 
# 		.window = 5;
# 		.threshold = 3;
# 	}
# }
# # backend web2_ssl { ... }

# # Define the director that determines how to distribute incoming requests.
# director default_director round-robin {
# 	{ .backend = web1; }
# 	{ ... }
# }

# director ssl_director round-robin {
# 	{ .backend = web1_ssl; }
# 	{ ... }
# }

# Respond to incoming requests.
sub vcl_recv {
	# Set the director to cycle between web servers.
	# if (server.port == 443) {
	# 	set req.backend = ssl_director;
	# } else {
		set req.backend = default_director;
	# }

	# Allow the backend to serve up stale content if it is responding slowly.
	set req.grace = 6h;

	# Use anonymous, cached pages if all backends are down.
	if (!req.backend.healthy) {
		unset req.http.Cookie;
	}

	# Always cache the following file types for all users.
	if (req.url ~ "(?i)\.(png|gif|jpeg|jpg|ico|swf|css|js|html|htm)(\?[a-z0-9]+)?$") {
		unset req.http.Cookie;
	}

	# Remove all cookies that Drupal doesn't need to know about. ANY remaining
	# cookie will cause the request to pass-through to Apache. For the most part
	# we always set the NO_CACHE cookie after any POST request, disabling the
	# Varnish cache temporarily. The session cookie allows all authenticated users
	# to pass through as long as they're logged in.
	if (req.http.Cookie) {
		set req.http.Cookie = ";" + req.http.Cookie;
		# set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
		# set req.http.Cookie = regsuball(req.http.Cookie, ";(SESS[a-z0-9]+|NO_CACHE)=", "; \1=");
		# set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
		# set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

		if (req.http.Cookie == "") {
			# If there are no remaining cookies, remove the cookie header. If there
			# aren't any cookie headers, Varnish's default behavior will be to cache
			# the page.
			unset req.http.Cookie;
		}
		else {
			# If there are any cookies left (a session or NO_CACHE cookie), do not
			# cache the page. Pass it on to Apache directly.
			return (pass);
		}
	}

	# Handle compression correctly. Different browsers send different
	# "Accept-Encoding" headers, even though they mostly all support the same
	# compression mechanisms. By consolidating these compression headers into
	# a consistent format, we can reduce the size of the cache and get more hits.
	# @see: http:// varnish.projects.linpro.no/wiki/FAQ/Compression
	if (req.http.Accept-Encoding) {
		if (req.http.Accept-Encoding ~ "gzip") {
			# If the browser supports it, we'll use gzip.
			set req.http.Accept-Encoding = "gzip";
		} else {
			if (req.http.Accept-Encoding ~ "deflate") {
				# Next, try deflate if it is supported.
				set req.http.Accept-Encoding = "deflate";
			}
			else {
				# Unknown algorithm. Remove it and send unencoded.
				unset req.http.Accept-Encoding;
			}
		}
	}
}

# Code determining what to do when serving items from the Apache servers.
sub vcl_fetch {
  # Allow items to be stale if needed.
  set beresp.grace = 6h;
}