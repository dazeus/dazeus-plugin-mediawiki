#!/usr/bin/perl
use strict;
use warnings;
use DaZeus;
use IO::Socket::INET;

my ($sourcehost, $listenport, $socket, $network, $channel) = @ARGV;
if(!$channel) {
	die "Usage: $0 sourcehost listenport socket network channel\n";
}

my $dazeus = DaZeus->connect($socket);
my $joined = 0;
foreach(@{$dazeus->networks()}) {
	if($_ eq $network) {
		$joined = 1;
		last;
	}
}
if(!$joined) {
	warn "Chosen network doesn't seem to be known in DaZeus...\n";
	warn "Known networks: " . join(', ', @{$dazeus->networks()}) . "\n";
	exit;
}

print "Sending to $channel on network $network.\n";

my $listen = IO::Socket::INET->new(
	Proto => "udp",
	Type => SOCK_DGRAM,
#/	LocalAddr => "::",
	LocalPort => $listenport,
	Blocking => 1,
);

if(!$listen) {
	die $!;
}

my $data;
while(my $sender = $listen->recv($data, 512)) {
	1 while chomp $data;
	my ($port, $ipaddr) = sockaddr_in($sender);
	my $ip_readable = join ".", unpack("C4", $ipaddr);
	my $hishost = gethostbyaddr($ipaddr, AF_INET);
	if($ip_readable ne $sourcehost && $hishost ne $sourcehost) {
		warn "Client $ip_readable [$hishost] sent something, but not equal to $sourcehost; ignoring\n";
		next;
	}
	print "<$sourcehost> $data\n";
	# without or with color
	if($data =~ /^\[\[[^\]]+?\]\] !M/ || $data =~ /^.\d\d\[\[.\d\d[^\]]+?.\d\d\]\].\d !M/) {
		print "(ignored)\n";
		next;
	}
	eval {
		$dazeus->message($network, $channel, $data);
	};
	if( $@ )
	{
		warn "Error executing message(): $@\n";
	}
}

1;
