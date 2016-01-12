## Gunpowder configs
ROOT='/nfs/gns/homes/nickl/dev/vb-rest-2015-12'
PORT=9300

export ENSEMBL_REST_ROOT=$ROOT
export ENSEMBL_REST_PORT=$PORT
export ENSEMBL_REST_CONFIG=$ROOT/vectorbase-rest/vectorbase_rest.conf
export ENSEMBL_REST_STARMAN=/nfs/public/rw/ensembl/perlbrew/perls/perl-5.16.3/bin/starman

export PERL5LIB=$ROOT/ensembl/modules-io:$ROOT/ensembl/modules:$ROOT/ensembl-compara/modules:$ROOT/ensembl-variation/modules:$ROOT/ensembl-funcgen/modules:$ROOT/vectorbase-rest/lib:$ROOT/ensembl-rest/lib:$ROOT/ensemblgenomes-api/modules:$ROOT/ensembl-io/modules:/nfs/public/rw/ensembl/bioperl-live:/nfs/public/rw/ensembl/bioperl-extra:/nfs/public/web-hx/tools/vcftools/perl:/nfs/public/rw/ensembl/tools/tabix:/nfs/public/rw/ensembl/tools/tabix/perl:/nfs/public/rw/ensembl/tools/tabix/perl/lib/site_perl/5.16.3/x86_64-linux:/net/isilonP/public/rw/homes/ens_adm/src/lib/site_perl/5.16.3/x86_64-linux
