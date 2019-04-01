#!/usr/bin/env perl

use v5.10.1;
use Test::More 'no_plan';
#use Smart::Comments;

my $connect_timeout = 10;   # curl connect timeout
my $max_time = 60;          # curl max timeout

my $TestName;

sub run_test ($$$);

my ($old_ip, $new_ip) = ($ENV{TEST_OLD_IP}, $ENV{TEST_NEW_IP});
if (!defined $old_ip) {
    print "ERROR: system environment TEST_OLD_IP is not defined.\n";
    exit 1;
}
if (!defined $new_ip) {
    print "ERROR: system environment TEST_NEW_IP is not defined.\n";
    exit 1;
}

my $filename = shift;

if (!defined $filename) {
    print "USAGE: TEST_OLD_IP=IP1 TEST_NEW_IP=IP2 perl test-http.pl FILENAME\n";
    exit 0;
}

open my $in, "<$filename" or
    die "Cannot open $filename for reading: $!\n";

while (<$in>) {
    chomp;

    # empty line.
    if (/^ \s* $/x) {
        next;
    }

    if (m{^ \s* (http[s]?) : // ([^:/\?\']+) (?: : (\d+) )? [^\s]* \s* $}x ) {
        my ($scheme, $host, $port) = ($1, $2, $3);
        if (!defined $port) {
            $port = $scheme eq "https" ? 443 : 80;
        }

        my $url = $_;

        run_test $url, $host, $port;

        sleep 0.1;

    } else {
        print "WARNING: invalid url: $_, skipping it.\n";
    }
}


sub parse_http_res ($) {
    my $out = shift;

    my ($status, @headers, $body);

    if ($out =~ /(.*?)\r\n\r\n(.*)/ms) {
        my $raw_hdr = $1;
        $body = $2;
        @headers = split /\r\n/, $raw_hdr;
    }

    my $first = shift @headers;
    if (!defined $first) {
        fail "$TestName - bad response: $out";
        return;
    }

    if ($first =~ m{^HTTP/\d+\.\d+ \s+ (\d+)\s}smxi) {
        $status = $1;

    } else {
        fail "$TestName - bad first response header line: $first\n";
        return;
    }

    my $headers = {};

    for my $header (@headers) {
        my ($key, $val) = split /:\s*/, $header, 2;

        $key = lc $key;

        if (defined $headers->{$key}) {
            $headers->{$key} .= "\n" . $val;

        } else {
            $headers->{$key} = $val;
        }
    }

    return ($status, $headers, $body);
}

sub http_req ($$$$) {
    my ($url, $host, $port, $ip) = @_;

    my $cmd = qq{curl -sS -i --connect-timeout $connect_timeout -m $max_time -4 --resolve "$host:$port:$ip" '$url'};
    #warn $cmd;

    my $out = `$cmd`;
    if ($? != 0) {
        fail "$TestName - failed to run curl: $?, cmd: $cmd";
        return;
    }

    parse_http_res $out;
}

sub run_test ($$$) {
    my ($url, $host, $port) = @_;

    $TestName = "GET $url";

    my ($old_status, $old_headers, $old_body) = http_req $url, $host, $port, $old_ip;

    my ($new_status, $new_headers, $new_body) = http_req $url, $host, $port, $new_ip;

    if (!defined($old_status) || !defined($new_status)) {
        return;
    }

    is $new_status, $old_status, "$TestName status matched";

    my $old_content_type = $old_headers->{'content-type'};
    my $new_content_type = $new_headers->{'content-type'};

    if (!defined($old_content_type) && !defined($new_content_type)) {
        ok 1, "$TestName both have no content-type";

    } else {
        is $new_content_type, $old_content_type, "$TestName content-type matched";
    }

    my $old_location = $old_headers->{'location'};
    my $new_location = $new_headers->{'location'};

    if (defined($old_location) || defined($new_location)) {
        is $new_location, $old_location, "$TestName location matched";
    }
}
