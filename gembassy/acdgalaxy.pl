#!/usr/bin/env perl
use strict;
use warnings;

my $progname = shift;
$progname =~ s/\.acd$//g;
my $progfile = "/usr/local/share/EMBOSS/acd/$progname.acd";
open my $acdfh, "<", $progfile;
open my $xmlfh, ">", "$progname.xml";

my $tool;
my $description;
my $command;
my @params;
my @args;
my $help;
my $plot = 0+`grep -c 'toggle: plot' $progfile`;
my $pngout = 0+`grep -c 'string: format' $progfile`;

while(<$acdfh>) {
    chomp;
    if(/\s*application\s*:\s*\w+\s*\[\s*$/../^\s*\]\s*$/) {
        if(/\s*application\s*:\s*(\w+)\s*\[\s*$/) {
            $tool = qq(<tool id="EMBOSS: $1" name="$1" version="1.0.2">);
        }

        if(/\s*documentation:\s*"([^"]+)"?\s*/) {
            my $tmp = $1;
            if(/\s*documentation:\s*".+"\s*/) {
                $description = qq(  <description>$tmp</description>);
            } else {
                while(<$acdfh>) {
                    if(/\s*(.*)"/) {
                        $tmp.= " $1";
                        last;
                    } elsif(/\s*(.*)\s*/) {
                        $tmp .= " $1";
                    }
                }
                $description = qq(  <description>$tmp</description>);
            }
        }
    }

    if(/\s*section\s*:\s*advanced\s*\[/../\s*endsection:\s*advanced/) {
        if(/\s*section\s*:\s*advanced\s*\[/../\]/ or /\s*endsction:\s*advanced/) {
            next;
        }

        if(/\s*\w+\s*:\s*\w+\s*\[/../\s*\]/) {
            if(/\s*(\w+)\s*:\s*(\w+)\s*\[/) {
                my ($type, $name) = ($1, $2);
                my $information;
                my $default;
                my @values;

                next if $name eq "accid";
                next if $name eq "plot";

                push @args, $name;

                while(<$acdfh>) {
                    chomp;
                    if(/\]/) {
                        last;
                    }
                    if(/\s*information:\s*"([^"]+)"?\s*/) {
                        my $tmp = $1;
                        if(/\s*information:\s*".+"\s*/) {
                            $information = $tmp;
                        } else {
                            while(<$acdfh>) {
                                if(/\s*(.*)"/) {
                                    $tmp.= " $1";
                                    last;
                                } elsif(/\s*(.*)\s*/) {
                                    $tmp .= " $1";
                                }
                            }
                            $information = $tmp;
                        }
                    }

                    if(/\s*default:\s*"(.+)"\s*/) {
                        $default = $1;
                    }

                    if(/\s*values:\s*"(.+)"\s*/) {
                        @values = split ";", $1;
                    }
                }
                #print "$type\t$name\t$information";
                #print "\t$default" if defined $default;
                #print "\n";
                my $param;

                if($default) {
                    $default = "yes" if $default eq "Y";
                    $default = "no"  if $default eq "N";
                    $default = "[^ACDEFGHIKLMNPQRSTVWYacgtU]" if $name eq "delkey";
                } else {
                    $default = "";
                }

                if($type eq "boolean") {
                    $param = <<EOS;
    <param name="$name" type="select" value="$default">
      <label>$information</label>
      <option value="no">No</option>
      <option value="yes">Yes</option>
    </param>
EOS
                }

                if($type =~ /(integer)|(float)|(string)/) {
                    $type =~ s/string/text/g;
                    $param = <<EOS;
    <param name="$name" size="4" type="$type" value="$default">
      <label>$information</label>
    </param>
EOS
                }

                if($type =~ /selection/) {
                    my $vals = join "\n", map{
                        "      <option value=\"$_\">". ucfirst($_) ."</option>"
                    }@values;
                    $param = <<EOS
    <param name="$name" type="select" value="$default">
      <label>$information</label>
$vals
    </param>
EOS
                }

                print "$type: $name\n";
                if($param && length $param) {
                    chomp($param);
                    push @params, $param;
                }
            }
        }
    }
}
close $acdfh;

my $args = join(" ", map{"-$_ \$$_"}@args);

my $paramstr = "";
foreach my $param (@params) {
    $paramstr .= "$param\n";
}

my $outputs;

if($plot) {
    $command = "<command interpreter=\"perl\">gembassy_calcandplot_wrapper.pl $progname -sequence \$input1 $args -auto \$out_file1 \$out_file2</command>";
    $outputs = <<EOS;
    <data format="csv" name="out_file1" label="\${tool.name} data for \${input1.name}" />
    <data format="png" name="out_file2" label="\${tool.name} plot for \${input1.name}" />
EOS
} elsif($pngout) {
    $command = "<command interpreter=\"perl\">emboss_single_outputfile_wrapper.pl $progname -sequence \$input1 -format png -goutfile \$out_file1 -auto $args</command>";
    $outputs = <<EOS;
    <data format="png" name="out_file1" label="\${tool.name} for \${input1.name}" />
EOS
} else {
    $command = "<command>$progname -sequence \$input1 $args -auto -outfile \$out_file1</command>";
    printf(STDERR "Enter output data format of $progname (1: txt 2: csv): ");
    chomp(my $format = <>);
    $format = $format == 1 ? "txt" : "csv";
    $outputs = <<EOS;
    <data format="$format" name="out_file1" label="\${tool.name} for \${input1.name}" />
EOS
}
chomp $outputs;

print $xmlfh <<EOS;
$tool
$description
  $command
  <inputs>
  <param format="data" name="input1" type="data">
    <label>Sequence</label>
  </param>
$paramstr
  </inputs>
  <outputs>
$outputs    
  </outputs>
</tool>
EOS

close $xmlfh;
