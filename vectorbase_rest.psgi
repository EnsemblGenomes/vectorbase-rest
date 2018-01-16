use strict;
use warnings;
use Plack::Builder;
use EnsEMBL::REST;
use Plack::Util;

my $app = EnsEMBL::REST->psgi_app;

builder {
## VB - handle /rest prefix  
  enable 'Rewrite', request => sub { s{^/rest(?=/|$)}{/}; return };
##  
  enable 'SizeLimit' => (
      max_unshared_size_in_kb => (800 * 1024),    # 800MB per process (memory assigned just to the process)
      check_every_n_requests => 10,
      log_when_limits_exceeded => 1
  );
  enable "Plack::Middleware::ReverseProxy";
  enable 'StackTrace';
  enable 'Runtime';
  enable "ContentLength";
  enable 'CrossOrigin', origins => '*', headers => '*', methods => ['GET','POST','OPTIONS'];
  $app;
}

