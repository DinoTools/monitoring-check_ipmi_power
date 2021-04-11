#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Pod::Text::Termcap;

use constant OK         => 0;
use constant WARNING    => 1;
use constant CRITICAL   => 2;
use constant UNKNOWN    => 3;

my $pkg_nagios_available = 0;
my $pkg_monitoring_available = 0;
my @g_long_message;

BEGIN {
    eval {
        require Monitoring::Plugin;
        require Monitoring::Plugin::Functions;
        $pkg_monitoring_available = 1;
    };
    if (!$pkg_monitoring_available) {
        eval {
            require Nagios::Plugin;
            require Nagios::Plugin::Functions;
            *Monitoring::Plugin:: = *Nagios::Plugin::;
            $pkg_nagios_available = 1;
        };
    }
    if (!$pkg_monitoring_available && !$pkg_nagios_available) {
        print("UNKNOWN - Unable to find module Monitoring::Plugin or Nagios::Plugin\n");
        exit UNKNOWN;
    }
}

my $parser = Pod::Text::Termcap->new (sentence => 0, width => 78);
my $extra_doc = <<'END_MESSAGE';

END_MESSAGE

my $extra_doc_output;
$parser->output_string(\$extra_doc_output);
$parser->parse_string_document($extra_doc);

my $mp = Monitoring::Plugin->new(
    shortname => "check_ipmi_power",
    usage => "",
    extra => $extra_doc_output
);

$mp->add_arg(
    spec     => 'hostname|H=s',
    help     => '',
    required => 1,
);

$mp->add_arg(
    spec     => 'username=s',
    help     => 'The IPMI username',
    required => 1,
);

$mp->add_arg(
    spec     => 'password=s',
    help     => 'The password of the IPMI user',
    required => 1,
);

$mp->add_arg(
    spec    => 'driver-type=s',
    help    => 'Specify the driver type to use (Default: lanplus)',
    default => 'lanplus',
);

$mp->getopts;

check();

my ($code, $message) = $mp->check_messages();
wrap_exit($code, $message . "\n" . join("\n", @g_long_message));

sub check
{
    my @cmd;
    push(@cmd, 'ipmi-power');
    push(@cmd, ('--driver-type', $mp->opts->{'driver-type'}));
    push(@cmd, ('--hostname', $mp->opts->hostname));
    push(@cmd, ('--username', $mp->opts->username));
    push(@cmd, ('--password', $mp->opts->password));
    push(@cmd, ('--privilege-level', 'USER'));
    push(@cmd, '--stat');

    open(my $pipe,'-|',@cmd) or wrap_exit(UNKNOWN, "Can't start process: $!");
    my @output=<$pipe>;
    close($pipe) or wrap_exit(UNKNOWN, "Broken pipe: $!" . "\nOutput: \n" . join("\n", @output));
    my $hop_count = 0;
    my $hop_reachable = 1;

    # Add default OK message
    $mp->add_message(
        OK,
        'System is on'
    );

    foreach my $line (@output) {
        if ($line =~ /^([^:]*?): (\w+)$/) {
            my $hostname = $1;
            my $state = $2;
            if ($state ne 'on') {
                $mp->add_message(
                    CRITICAL,
                    sprintf(
                        'System is not on: \'%s: %s\'',
                        $hostname,
                        $state
                    )
                );
            }
        } else {
            $line =~ s/^\s+|\s+$//g;
            wrap_exit(
                UNKNOWN,
                sprintf(
                    'Unable to parse output: \'%s\'',
                    $line
                )
            );
        }
    }
}

sub wrap_exit
{
    if($pkg_monitoring_available == 1) {
        $mp->plugin_exit( @_ );
    } else {
        $mp->nagios_exit( @_ );
    }
}
