#!/usr/bin/env perl
use warnings;

my $script = shift;
open OUT, ">", shift;
open STDOUT, ">", shift;
open STDERR, ">", shift;

print OUT $script, "\n";

my $open = "";
my @files;
for(my $i = 0; @ARGV; $i++) {
    my $fn = shift;
    push @files, $fn;
    $open .= qq(open IN$i, "<", "$fn";\n);
}

if($script =~ /(open)|(system)|(`.+`)|([$@%]ENV)/smg) {
    printf(STDERR "Found vulnerable code (open, system, backticks) in given script.");
    exit(1);
}

eval("$open$script");

close OUT;
