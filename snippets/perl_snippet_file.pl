#!/usr/bin/env perl
use warnings;

my $scriptname = shift;
my $outname = shift;
open SCR, "<", $scriptname;
open OUT, ">", $outname;
open STDOUT, ">", shift;
open STDERR, ">", shift;

my $open = "";
my @files;
for(my $i = 0; @ARGV; $i++) {
    my $fn = shift;
    push @files, $fn;
    $open .= qq(open IN$i, "<", "$fn";\n);
}

my $script = join("", <SCR>);

if($script =~ /(open)|(system)|(`.+`)|([$@%]ENV)/smg) {
    printf(STDERR "Found vulnerable code (open, system, backticks) in given script.");
    exit(1);
}

eval("$open$script");

close SCR;
close OUT;
