# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
# 
# Default backend definition.  Set this to point to your content
# server.
# 
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

sub vcl_recv {


  if (req.request != "GET" &&
    req.request != "HEAD" &&
    req.request != "PUT" &&
    req.request != "POST" &&
    req.request != "TRACE" &&
    req.request != "OPTIONS" &&
    req.request != "DELETE") {
      /* Non-RFC2616 or CONNECT which is weird. */
      return (pipe);
  }

  if (req.request != "GET" && req.request != "HEAD") {
    /* We only deal with GET and HEAD by default */
    return (pass);
  }

  // Remove has_js and Google Analytics cookies.
#  set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(__[a-z]+|__utma_a2a|has_js)=[^;]*", "");

  // To users: if you have additional cookies being set by your system (e.g.
  // from a javascript analytics file or similar) you will need to add VCL
  // at this point to strip these cookies from the req object, otherwise
  // Varnish will not cache the response. This is safe for cookies that your
  // backend (Drupal) doesn't process.
  //
  // Again, the common example is an analytics or other Javascript add-on.
  // You should do this here, before the other cookie stuff, or by adding
  // to the regular-expression above.

  if (req.url ~ "\.(css)\?") {
	set req.url = regsub(req.url, "(.*)\.(.*)\?(.*)$", "\1.\2");
	unset req.http.cookie;
        return(lookup);
  }
  
  if (req.url ~ "\.(.*)\?v=") {
        set req.url = regsub(req.url, "(.*)\.(.*)\?v=(.*)$", "\1.\2");
        unset req.http.cookie;
        return(lookup);
  }

  if (req.url ~ "\.(jpg|jpeg|png|css|js)$") {
	unset req.http.cookie;
        return(lookup);
  }

}

sub vcl_fetch {
    set beresp.http.X-Backend = beresp.backend.name;
    set beresp.grace = 30s;
    if (req.url ~ "\.(png|css|jpg|jpeg|js)") {
	unset beresp.http.set-cookie;
#	set beresp.http.Cache-Control = "max-age=86400";
#      	set beresp.ttl = 24h;
	return(deliver);
    }
}
