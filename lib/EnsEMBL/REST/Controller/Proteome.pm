=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute 
Copyright [2016-2018] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::REST::Controller::Proteome;

use File::Spec::Functions qw(catfile);
use JSON::XS;

use Moose;
use namespace::autoclean;

use Try::Tiny;
require EnsEMBL::REST;

BEGIN { extends 'Catalyst::Controller::REST'; }
__PACKAGE__->config(
  map => {
    'text/html'           => [qw/View FASTAHTML/],
    'text/plain'          => [qw/View SequenceText/],
    'text/x-fasta'        => [qw/View FASTAText/],
    'text/x-seqxml+xml'   => [qw/View SeqXML/],
    'text/x-seqxml'       => [qw/View SeqXML/], #naughty but needs must
  }
);
EnsEMBL::REST->turn_on_config_serialisers(__PACKAGE__);


# This list describes user overridable variables for this endpoint. It protects other more fundamental variables
has valid_user_params => ( 
  is => 'ro', 
  isa => 'HashRef', 
  traits => ['Hash'], 
  handles => { valid_user_param => 'exists' },
  default => sub { return { map {$_ => 1} (qw/
    multiple_sequences
    /) }
  }
);

has 'max_slice_length' => ( isa => 'Num', is => 'ro', default => 1e7);

has 'data_path' => ( isa => 'Str', is => 'ro', default => '/vectorbase/ebi/pep_json/');
has 'data_sfx' => ( isa => 'Str', is => 'ro', default => '.json.gz');

has allowed_values => (isa => 'HashRef', is => 'ro', default => sub {{
  type => { map { $_, 1} qw(protein) },
}});

with 'EnsEMBL::REST::Role::PostLimiter','EnsEMBL::REST::Role::SliceLength','EnsEMBL::REST::Role::Content';


sub proteome_GET {
  my ($self, $c) = @_;
  $c->request->params->{'multiple_sequences'} = 1;
  try {
    $self->_get_proteome_sequences($c);
  } catch {
    $c->go('ReturnError', 'from_ensembl', [qq{$_}]) if $_ =~ /STACK/;
    $c->go('ReturnError', 'custom', [qq{$_}]);
  };
  $self->_write($c);
}

sub proteome :Chained('/') PathPart('sequence/proteome') Args(1) ActionClass('REST'){
  my ($self, $c, $species) = @_;
  $c->stash()->{species} = $species;
}

sub _get_proteome_sequences {
  my ($self, $c) = @_;

  my $species = $c->stash()->{species};
  my $ename = $c->model('Registry')->get_alias($species);
  Catalyst::Exception->throw("Do not know anything about the species $species") unless $ename;

  my $filename = $ename . $self->{data_sfx};
  my $fpath = catfile($self->{data_path}, $filename);
  (-e $fpath) or 
    Catalyst::Exception->throw( "No data for $ename");

  my $opener = ($filename =~ /.gz$/) ? "zcat $fpath |" : "<$fpath";
  open (JSONFILE, $opener) or
    Catalyst::Exception->throw( "No data for $ename can be used");

  my $json = '';
  while(<JSONFILE>) {
    $json .= $_;
  }
  close(JSONFILE);
  Catalyst::Exception->throw( "No valid data for $ename") unless $json;

  my $proteins;
  eval { $proteins = decode_json($json) };
  $json = '';
  Catalyst::Exception->throw( "No valid data for $ename") unless $proteins;

  my $seq_stash = $c->stash()->{sequences};
  for my $protein (@$proteins) {
    push @$seq_stash, {
      id => $protein->{id},
      molecule => 'protein',
      query => $species,
      seq => $protein->{seq},
    };
  }
  $c->stash()->{sequences} = $seq_stash;
}

sub _write {
  my ($self, $c) = @_;
  my $s = $c->stash();
  my $data = $s->{sequences};
  if ((defined $data && scalar @$data == 0) || !defined $data) {
    $self->status_not_found($c, message => 'No results found');
    return;
  }
  if($c->request->param('multiple_sequences')) {
    $self->status_ok($c, entity => $data);
  }
  else {
    $self->status_ok($c, entity => $data->[0]);
  }
}

sub _include_user_params {
  my ($self,$c,$user_config) = @_;

  foreach my $key (keys %$user_config) {
    if ($self->valid_user_param($key)) {
      $c->request->params->{$key} = $user_config->{$key};
    }
  }
}

__PACKAGE__->meta->make_immutable;

1;

