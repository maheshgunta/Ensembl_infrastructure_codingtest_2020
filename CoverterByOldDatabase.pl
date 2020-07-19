#!/usr/bin/env perl

use strict;
use warnings;

use IO::File;
use Getopt::Long;

use Bio::EnsEMBL::Registry;

my ( $filename );

$filename='assemblyconverter.in';

my $registry = 'Bio::EnsEMBL::Registry';

my $host = 'ensembldb.ensembl.org';
my $port = 3337;
my $user = 'anonymous';


$registry->load_registry_from_db( '-host' => $host,
                                  '-port' => $port,
                                  '-user' => $user );

my $slice_adaptor = $registry->get_adaptor( 'Human', 'Core', 'Slice' );

my $in = IO::File->new($filename);

while ( my $line = $in->getline() ) {
  chomp($line);

  my $number_seps_regex = qr/\s+|,/;
  my $separator_regex = qr/(?:-|[.]{2}|\:|_)?/;
  my $number_regex = qr/[0-9, E]+/xms;
  my $strand_regex = qr/[+-1]|-1/xms;

  my $regex = qr/^(\w+) $separator_regex (\w+) $separator_regex ((?:\w|\.|_|-)+) \s* :? \s* ($number_regex)? $separator_regex ($number_regex)? $separator_regex ($strand_regex)? $/xms;

  my ( $old_cs_name, $old_version, $old_sr_name, $old_start, $old_end, $old_strand );

  if ( ($old_cs_name, $old_version, $old_sr_name, $old_start, $old_end, $old_strand) = $line =~ $regex) {
  } else {
    printf( "Invalid file format :\n%s\n", $line );
    next;
  }

my $old_slice =
    $slice_adaptor->fetch_by_region(
                                $old_cs_name, $old_sr_name, $old_start,
                                $old_end,     $old_strand,  $old_version
    );

  $old_cs_name ||= $old_slice->coord_system_name();
  $old_sr_name ||= $old_slice->seq_region_name();
  $old_start   ||= $old_slice->start();
  $old_end     ||= $old_slice->end();
  $old_strand  ||= $old_slice->strand();
  $old_version ||= $old_slice->coord_system()->version();

  printf( "#Input %s\n", $old_slice->name() );

  foreach my $segment ( @{ $old_slice->project('chromosome') } ) {

    printf( "%s:%s:%s:%d:%d:%d,%s\n",
            $old_cs_name,
            $old_version,
            $old_sr_name,
            $old_start + $segment->from_start() - 1,
            $old_start + $segment->from_end() - 1,
            $old_strand,
            $segment->to_Slice()->name() );
  }
  print("\n");

} 
