# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
# Copyright [2016-2018] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

BEGIN {
  use FindBin qw/$Bin/;
  use lib "$Bin/lib";
  use RestHelper;
  # NB: using ENSEMBL_REST_CONFIG instead of CATALYST_CONFIG
  $ENV{ENSEMBL_REST_CONFIG} = "$Bin/../vectorbase_rest_testing.conf";
  $ENV{ENS_REST_LOG4PERL} = "$Bin/../log4perl_testing.conf";
}

use Test::More;
use Test::Deep;
use Catalyst::Test ();
use Bio::EnsEMBL::Test::MultiTestDB;

my $dba = Bio::EnsEMBL::Test::MultiTestDB->new('anopheles_atroparvus');
Catalyst::Test->import('EnsEMBL::REST');

# species specific proteome download
{
  my $species = 'very_hungry_mosquito';
  my $url = "/sequence/proteome/$species?";
  action_check_code($url, 400, 'Return code for unavailable species should be 400');
  action_raw_bad_regex($url, qr/Do not know anything about the species/, 'There\'s no available species with such name or core db for it');
}

{
  my $species = 'anopheles_atroparvus';
  my $url = "/sequence/proteome/$species?";
  my $fasta = fasta_GET($url, 'Getting whole proteome as a single fasta');
  my $expected = <<'FASTA';
>AATE000001-PA
MRNNVLSSKNPNNNNNNSAMGSFYEDNNAQFVPSVSGNGGSAVVSGNGNGLKRPATLELN
PSAGKARKTRYNASVTVPSVLPSPDMAMLTTVSPELEKIISHNAALPTPTPSAIIFPPSA
SAEQQQFAKGFEDALMNIHKKDTSNKLNTSNNNNTCTSNNNNTSSSSTSSSNQQAVNVSV
AAQIQLCPTTTATSVCNSLLTGGLNGMSGGEMTYTNLDKYPGLVKEEPQATSSNQSPPIS
PIDMDSQERIKLERKRLRNRVAASKCRRRKLERISKLEDKVKDLKTQNSELGSMVCNLKQ
HIFQLKQQVLEHHNSGCTITLVGKF
>AATE000002-PA
MRSRSAFFVVCGLVLLAFGVQMGFGIKCWECRSDSDPKCADPFDNSTLSITDCRQLNEKE
HLPGVKATMCRKIRQKVHGEWRYFRSCAFMGEPGIEGDERFCLMRSGTYNIFMEYCTCNS
KDGCNAGSYRSPTVVLISSALMVCFSVVAVFRRV
>AATE000003-PA
MPATGRNWTGHGQPVAGGGSARDAVARAALAAPRRNPSPPVPLQVVPEALDLAELVMAAG
GRAGPVVLVAARVATARLVRRMPVVVVVVMVMLLLVLVAVLLALLLLLLLAAIATGPPAH
TTGTLRLVQYSLVELLDRPPAVAPPPPPPPPLPLRLLSWKLESSSAGLSPVWKLITLMLY
VTVDDWRLRPRRGCCGEGVMMEGARDGVTVREVGEREAAVALLSITMSGLASASSIISLA
MSIVVTVAGADVGTRGSFSLGLVATRSSEMVDASLS
>AATE000004-PA
MLSVKNFTMVRCFHKGVQTARGATVLNEQTKKCVRNPNKSSSLTHLPDYTFMDGRVTPFG
ANQKKRILQQREIAKQIVTLSKEMDFAVERYNRINAENEQRKSDLLREKLKPKGHLLLKK
TK
FASTA
  is($fasta, $expected, 'Getting whole proteome as a single fasta');
}

#
done_testing();
