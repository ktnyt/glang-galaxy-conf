#! /usr/bin/perl -w
use strict;
use File::Copy;

my $png_outfile = pop(@ARGV);
my $csv_outfile = pop(@ARGV);

my $csv_cmd = join(" ", (@ARGV, "-noplot -outfile $csv_outfile"));
my $png_cmd = join(" ", (@ARGV, "-plot -graph png -goutfile $png_outfile"));

my $csv_results = `$csv_cmd`;
my $png_results = `$png_cmd`;
my @files = split("\n", $png_results);
my ($drive, $outputDir, $file) = File::Spec->splitpath( $png_outfile );

foreach my $thisLine (@files)
  {
      if ($thisLine =~ /Created /)
        {
            $thisLine =~ /[\w|\.]+$/;
            $thisLine = $&;
            #print "outfile: $thisLine\n";
            #there is only one file to move, so we can quit after finding it
            move($drive.$outputDir.$thisLine, $png_outfile);
            exit(1);
        }
      else
        {
            print $thisLine, "\n";
        }
  }
