vcl 4.0;
import directors;    # load the directors

# Define the list of backends (web servers).
backend web1 {
    .host = "10.0.9.4"; # /global_nginx.1.4ov1ss8l64ldsldnypukounrt automated discovery
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}
backend web2 {
    .host = "10.0.9.5"; # /global_nginx.2.yfgxgwnfxcr1xkf9nyq3m4g6f automated discovery
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}
backend web3 {
    .host = ""; # /global_nginx.2.56aa5yp2odbrtbk0dolp4j0og automated discovery
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}
backend web4 {
    .host = ""; # /global_nginx.1.75bm64qk9e0oxn3yzlktciz6v automated discovery
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}
backend web5 {
    .host = ""; # /global_nginx.2.uu98bpg48qag3hiaefjx3d4ii automated discovery
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}
backend web6 {
    .host = ""; # /global_nginx.1.r5nskdayivw1q3pqy6xacnuh8 automated discovery
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}
backend web7 {
    .host = ""; # /global_nginx.2.egicoat4052m0harte1b9ueem automated discovery
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}
backend web8 {
    .host = ""; # /global_nginx.1.9frm1xs69jr9nscqwkl59j8g2 automated discovery
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}
backend web9 {
    .host = ""; # /global_nginx.2.ku5w6ujqsyf5n6xg1d2bgg4i2 automated discovery
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}
backend web10 {
    .host = ""; # /global_nginx.1.cwtpsrjrhi2g16z4oj6t7x185 automated discovery
    .port = "80";
    .probe = {
        .url = "/";
        .timeout = 1s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}

# 10 hosts discovered

# Define the director that determines how to distribute incoming requests.
sub vcl_init {
    new bar = directors.round_robin();
    bar.add_backend(web1);
    bar.add_backend(web2);
    bar.add_backend(web3);
    bar.add_backend(web4);
    bar.add_backend(web5);
    bar.add_backend(web6);
    bar.add_backend(web7);
    bar.add_backend(web8);
    bar.add_backend(web9);
    bar.add_backend(web10);
}

# Respond to incoming requests.
sub vcl_recv {
	set req.backend_hint = bar.backend();
	# Set the director to cycle between web servers.
	# if (server.port == 443) {
	# 	set req.backend = ssl_director;
	# } else {
		# set req.backend = default_director;
	# }

	# # Allow the backend to serve up stale content if it is responding slowly.
	# set req.grace = 6h;

	# # Use anonymous, cached pages if all backends are down.
	# if (!req.backend.healthy) {
	# 	unset req.http.Cookie;
	# }

	# # Always cache the following file types for all users.
	# if (req.url ~ "(?i)\.(png|gif|jpeg|jpg|ico|swf|css|js|html|htm)(\?[a-z0-9]+)?$") {
	# 	unset req.http.Cookie;
	# }

	# # Remove all cookies that Drupal doesn't need to know about. ANY remaining
	# # cookie will cause the request to pass-through to Apache. For the most part
	# # we always set the NO_CACHE cookie after any POST request, disabling the
	# # Varnish cache temporarily. The session cookie allows all authenticated users
	# # to pass through as long as they're logged in.
	# if (req.http.Cookie) {
	# 	set req.http.Cookie = ";" + req.http.Cookie;
	# 	# set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
	# 	# set req.http.Cookie = regsuball(req.http.Cookie, ";(SESS[a-z0-9]+|NO_CACHE)=", "; \1=");
	# 	# set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
	# 	# set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

	# 	if (req.http.Cookie == "") {
	# 		# If there are no remaining cookies, remove the cookie header. If there
	# 		# aren't any cookie headers, Varnish's default behavior will be to cache
	# 		# the page.
	# 		unset req.http.Cookie;
	# 	}
	# 	else {
	# 		# If there are any cookies left (a session or NO_CACHE cookie), do not
	# 		# cache the page. Pass it on to Apache directly.
	# 		return (pass);
	# 	}
	# }

	# # Handle compression correctly. Different browsers send different
	# # "Accept-Encoding" headers, even though they mostly all support the same
	# # compression mechanisms. By consolidating these compression headers into
	# # a consistent format, we can reduce the size of the cache and get more hits.
	# # @see: http:// varnish.projects.linpro.no/wiki/FAQ/Compression
	# if (req.http.Accept-Encoding) {
	# 	if (req.http.Accept-Encoding ~ "gzip") {
	# 		# If the browser supports it, we'll use gzip.
	# 		set req.http.Accept-Encoding = "gzip";
	# 	} else {
	# 		if (req.http.Accept-Encoding ~ "deflate") {
	# 			# Next, try deflate if it is supported.
	# 			set req.http.Accept-Encoding = "deflate";
	# 		}
	# 		else {
	# 			# Unknown algorithm. Remove it and send unencoded.
	# 			unset req.http.Accept-Encoding;
	# 		}
	# 	}
	# }
}

# # Code determining what to do when serving items from the Apache servers.
# sub vcl_fetch {
#   # Allow items to be stale if needed.
#   set beresp.grace = 6h;
# }