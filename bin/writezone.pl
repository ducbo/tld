#!/usr/bin/env perl

# Zone writer for cyberman.
# This won't scale well, but it's a basic way to get domains online
# Tested with NSD but should work with your favourite

use strict;
use warnings;
use feature 'say';
use FindBin qw($Bin);
use YAML::Tiny;
use DBI;
use Capture::Tiny ':all';

my $yml = YAML::Tiny->read("$Bin/../config.yml");
my $tld = $yml->[0]->{"tld"};
my $conf = $yml->[0]->{"zonewriter"};

die "Unsupported database!"
	unless $yml->[0]->{"plugins"}->{"Database"}->{"driver"} eq "SQLite";
my $dbfile = "$Bin/../$yml->[0]->{plugins}->{Database}->{dbname}";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");

my $sth = $dbh->prepare("SELECT * from cyberman");
$sth->execute;
my $cyberman = $sth->fetchrow_hashref;
exit unless $cyberman->{"intserial"} > $cyberman->{"lastserial"};

my $zone;

# Introduction
$zone .= <<"END";
END

# Write SOA
# Uses mostly hard-coded values for now
$zone .= "@  1  IN  SOA $conf->{ns} $conf->{responsible} (\n" . time . "\n";
$zone .= <<'END';
1800 ; refresh
3600 ; retry
3600 ; expire
3600 ; nxdomain ttl
)
END
$zone .= <<"END";
\@ IN NS a.vn.al.
\@ IN NS b.vn.al.
\@ IN MX 1 aspmx.l.google.com.
\@ IN MX 5 alt1.aspmx.l.google.com.
\@ IN MX 10 aspmx2.googlemail.com.
\@ IN MX 10 aspmx3.googlemail.com.
\@ IN A  185.215.234.2
\@ IN A  185.215.235.2
END
# Time to get the records
$sth = $dbh->prepare("SELECT * FROM record");
$sth->execute;

while (my $r = $sth->fetchrow_hashref) {
	# Look up domain
	my $dsth = $dbh->prepare("select * from domain where id=?");
	$dsth->bind_param(1, $r->{"domainid"});
	$dsth->execute;
	my $d = $dsth->fetchrow_hashref;

	# domain name
	if ($r->{"name"} eq '@') {
		$zone .= $d->{"name"} . " ";
	} else {
		$zone .= $r->{"name"} . "." . $d->{"name"} . " ";
	}

	# record type
	$zone .= "IN $r->{type} ";

	# value
	$zone .= "$r->{value}\n";
}

if ($conf->{"validate"}) {
	my $checkzone_exit;
	capture {
		open my $checkzone, "| nsd-checkzone $tld -" or die $!;
		print $checkzone $zone;
		close $checkzone;
		$checkzone_exit = $?;
	};
	if ($checkzone_exit != 0) {
		$sth = $dbh->prepare("UPDATE cyberman SET zonecheckstatus=1");
		$sth->execute;
		exit;
	}
}

if ($conf->{"include"}->{"enabled"}) {
	$zone .= "\$INCLUDE $conf->{include}->{file}\n";
}

open my $out, ">", $conf->{"file"} or die $!;
say $out $zone;
close $out;

$sth = $dbh->prepare("UPDATE cyberman SET lastserial=?, zonecheckstatus=0");
$sth->bind_param(1, $cyberman->{"intserial"});
$sth->execute;
