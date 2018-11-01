#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use Getopt::Long qw(:config no_auto_abbrev);
use Pod::Usage;

use Bio::SeqIO;
use JSON::XS qw(encode_json);


main();

sub main {
  my ($reg_conf, $fa_dir, $j_dir);
  my ($shorten_names, $file_mask, $split_mask, $gzip_result); 
  my ($help, $verbose);


  $|=1;   # make STDOUT unbuffered (STDERR is unbuffered anyway)
  
  #defaults
  $split_mask = '_PEPTIDES_';
  $file_mask = '*_PEPTIDES_*.fa.gz';

  GetOptions(
    'reg_conf|regfile|reg_file=s'  => \$reg_conf,
    'fa_dir|fasta_dir|input_dir=s'  => \$fa_dir,
    'j_dir|json_dir|output_dir=s'  => \$j_dir,

    'shorten_names'                  => \$shorten_names,
    'file_mask:s'                  => \$file_mask,
    'split_mask:s'                  => \$split_mask,
    'gzip_result'                  => \$gzip_result,

    # Other commands
    'h|help'                     => \$help,
    'v|verbose'                  => \$verbose,
  ) or pod2usage(2);

  if (@ARGV) {
    die "ERROR: There are invalid arguments on the command-line: ". join(" ", @ARGV). "\n";
  }

  if ($help) {
    pod2usage({-exitvalue => 0, -verbose => 2});
  }

  (defined $reg_conf && -f $reg_conf) or
    die("can't find registry file: ", $reg_conf || '', "\n");
  require Bio::EnsEMBL::Registry;
  Bio::EnsEMBL::Registry->load_all($reg_conf);

  #generate filename prefix to species mapping
  my %spec4pfx = ();
  my @dbas = @{ Bio::EnsEMBL::Registry->get_all_DBAdaptors(-group => 'core') };
  for my $dba (@dbas) {
    my $species = $dba->species();
    my ($pfx, $ver) = gen_dump_name_pfx($dba);
    $spec4pfx{$pfx} = $species;
  }

  (defined $fa_dir) or die "no input dir specified";
  (-e $fa_dir && -d $fa_dir) or
    die("no such input dir $fa_dir\n");

  (defined $j_dir) or die "no output dir specified";
  unless (-e $j_dir && -d $j_dir) {
    system("mkdir -p $j_dir") == 0 or
      die("Can't create output dir $j_dir: $!\n");
  }


  my $seen = 0;  
  my @skipped = ();
  
  my $pat = $file_mask;
  $pat =~ s/([\.\\\$])/\\$1/g;
  $pat =~ s/\*/.\*/g;
  $pat = "^$pat\$";
  
  # iterate through the files in input dir
  opendir(FADIR, $fa_dir) or
    die("Can't open input dir $fa_dir: $!\n");
  while (defined(my $file = readdir(FADIR))) {
    next unless $file =~ m/$pat/;
    ++$seen;

    my $from_file = catfile($fa_dir, $file);

    my @parts = split($split_mask, $file);
    if (!exists $spec4pfx{$parts[0]}) {
       warn "$file has no corresponding species name\n";
       push @skipped, $from_file;
       next;
    };
    my $spec = $spec4pfx{$parts[0]};

    my $to_file = catfile($j_dir, $spec.'.json');
    gen_json($from_file, $to_file, $shorten_names) or push(@skipped, $from_file);
  }
  closedir(FADIR);

  $seen and
     warn "seen $seen files matching $file_mask (", $seen - scalar(@skipped)," processed)\n" or
     warn "no input files matching pattern $file_mask\n";

  scalar(@skipped) and
     warn "skipped files: ", join(", ", @skipped), "\n"

}

sub gen_dump_name_pfx {
  # from eg-pipelines/modules/Bio/EnsEMBL/EGPipeline/FileDump/BaseDumper.pm : generate_vb_filename  
  # my $filename = ucfirst($species).'-'.$strain.'_'.uc($data_type).'_'."$version.$file_type";

  my ($dba) = @_;
  my $species = $dba->species();
  my $strain  = $dba->get_MetaContainer()->single_value_by_key('species.strain');

  my $gb_ver = $dba->get_MetaContainer()->single_value_by_key('genebuild.version');
  my $as_ver = $dba->get_MetaContainer()->single_value_by_key('assembly.default');

  $species =~ s/_/-/;
  $species =~ s/_.+$//;
  $strain =~ s/[\s\/]+/\-/g;

  my $ver = $gb_ver || $as_ver || '';
  my $filename = ucfirst($species).'-'.$strain;

  return ($filename, $ver);
}

sub gen_json {
  my ($from_file, $to_file, $shorten_names, $gzip_result) = @_;

  open my $input, ($from_file =~ m/\.gz$/
      ? "zcat $from_file |"
      : "$from_file>") or
    warn "failed to process $from_file: $!" and
    return 0;
  
  my @data = ();
  my $gen_id = $shorten_names
    ? sub { my ($s) = @_; $s->primary_id() }
    : sub { my ($s) = @_; join(' ', $s->display_id(), $s->desc()) };

  my $seq_io = Bio::SeqIO->new(-fh => $input, -format => 'fasta');
  while(my $seq = $seq_io->next_seq()) {
    push @data, { id => $gen_id->($seq), seq => $seq->seq() };
  }
  close($input);

  if (!scalar(@data)) {
    warn "no sequences for $from_file";
    return 0;
  }

  my $writer = $gzip_result? "| gzip - > ${to_file}.gz" : "> ${to_file}";

  open (my $output, $writer) or
    warn "failed to open $to_file as output for $from_file: $!" and
    return 0;
  print $output encode_json(\@data);  
  close($output);

  return 1;
}

__END__

=head1 NAME

  pepfa2json.pl -- converting peptides fastas from dump to json

=head1 SYNOPSIS

  pepfa2json.pl [options]

=head2 Other options:

=over

=item --help

print this help

=item -reg_file <registry file>

registy file used for data dump generation

=item -fasta_dir <input directory>

fasta dir with *_PEPTIDES_*fa.gz [see file_mask option] 

=item -json_dir <output directory>

output_dir to write jsons to

=item -gzip_result

gzip output json files

=item -shorten_names

print only FASTA ids, no description

=item -file_mask <string>

file mask to use to find the peptides fastas.
default: [*_PEPTIDES_*.fa.gz]

=item -split_mask <string>

part of the filename, separating species and technical information.
default: [_PEPTIDES_]

=back

i.e. ./pepfa2json.pl \
       -reg_file ./file_dumping.reg \
       -fa_dir ./file_dump_vb_93 \
       -j_dir pep_json \
       -gzip_result \
       -shorten_names

=head1 CONTACT

Please email comments or questions to the
VectorBase help desk
<https://www.vectorbase.org/contact>

=cut
