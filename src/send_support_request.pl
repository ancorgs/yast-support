#!/usr/bin/perl -w
#------------------------------------------------------------------------
# Copyright (c) 2000 SuSE GmbH Nuernberg, Germany.  All rights reserved.
#------------------------------------------------------------------------
# Author   : Gregor Fischer <fischer@suse.de>
# Created  : 13.12.2000
# Modified : 14.14.2000
#------------------------------------------------------------------------
# This script take the data from the files passed as arguments
# and send it to the SuSE support server to create a new inquiry.
#
# For more information have a look at http://support.suse.de/
#------------------------------------------------------------------------
# Usage: send_support_request.pl file1 [file2 [file3 [...]]]
#------------------------------------------------------------------------
# Result: On success is silent and return 0.
# On error prints reason to STDERR an returns non-null value:
# 10: No input files were specified
# 11: No data could be collected from input files
# 20: Error connecting to server
# 21: The Server-Response did not comply with the HTTP protocol
# Other != 200: Return code of HTTP server
#------------------------------------------------------------------------
use strict;
use IO::Socket;

#my $HOST    = "support.suse.de";
my $HOST    = "pell.suse.de";
my $PORT    = 80;
my $URL     = "/cgi-bin/yast2_request.pl";
my $VERSION = "0.1.0";
#------------------------------------------------------------------------
sub abort {
    my $ErrorNumber = shift;
    my $ErrorText = shift;

    warn("$ErrorText (Error $ErrorNumber)\n");
    exit($ErrorNumber);
}
#------------------------------------------------------------------------
sub escape {
    my $data = shift;
    return undef unless (defined $data);
    $data =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $data;
}
#------------------------------------------------------------------------
sub submit {
    my $data = shift;

    my $length = length($data);
    my $socket = undef;
    
    eval {
	$socket = IO::Socket::INET->new(
		PeerAddr => $HOST,
		PeerPort => $PORT,
		Proto    => 'tcp',
		Type     => SOCK_STREAM, 
	);
    };
    abort(20, "Cannot connect to $HOST") unless ($socket);

    print $socket "POST $URL HTTP/1.0\n";
    print $socket "User-Agent: YaST2-Support-Request-Generator/$VERSION\n";
    print $socket "Content-type: application/x-www-form-urlencoded\n";
    print $socket "Content-length: $length\n";
    print $socket "\n";
    print $socket $data;

    my @answer = <$socket>;
    close($socket);

    if ($answer[0] =~ /^HTTP.*?\s+(\d+)\s+(.*?)\s*$/) {
	if ($1 == 200) {
	    return $2;
	} else {
	    abort($1,$2);
	}
    } else {
	chomp $answer[0];
	abort(21, "Unknown server response: $answer[0]");
    }
}
#------------------------------------------------------------------------
sub main {
    # Check arguments
    unless (@ARGV) {
#	print STDERR "Usage: $0 file1 [file2 [file3 [...]]]\n";
#	print STDERR "Version: $VERSION\n";
#	abort(10, "No input files.");
	exit 0;
    }
    
    # Collect data
    my $data = join("", <>);
#    abort(11, "No data.") unless ($data);
    exit 0 unless ($data);

    # Escape data
    $data = escape($data);

    # Send data
    submit("data=$data");
    
    exit(0)
}
#------------------------------------------------------------------------
main();

