use strict;
use warnings;
use EnsEMBL::REST;
use Plack::Builder;
use Plack::Util;

my $app = EnsEMBL::REST->apply_default_middlewares(EnsEMBL::REST->psgi_app);

builder {
## VB - handle /rest prefix  
  enable 'Rewrite', request => sub { s{^/rest(?=/|$)}{/}; return };
##  
  enable 'DetectExtension';
  enable 'EnsemblRestHeaders';
  enable 'CrossOrigin', origins => '*', headers => '*', methods => ['GET','POST','OPTIONS'];
  $app;
}