You'll need to have:
  1. ensebl-rest and its dependencies (BioPerl and various ensembl stuff). Properly set up PERL5LIB.
  2. PERL5LIB to have  ensembl-rest/t/lib
     (i.e. PERL5LIB=$PERL5LIB:../ensembl-rest/t/lib)

i.e. one can run tests as following (bash):
source ../vectorbase-rest/bin/env.sh; PERL5LIB=`pwd`/lib:$(echo `pwd`/../*/modules | perl -pe 's/ /:/g'):`pwd`/../ensembl-rest/t/lib:$PERL5LIB ENSEMBL_REST_CONFIG= perl t/proteome.t

