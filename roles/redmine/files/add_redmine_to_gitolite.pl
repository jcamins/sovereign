#!/usr/bin/perl

use strict;
use warnings;
use File::Temp qw/tempdir/;
use File::Copy;
use Sys::Hostname;

my $fh;
my $hostname = hostname;

my $dir = tempdir(CLEANUP => 1);
system("git clone /home/git/repositories/gitolite-admin.git $dir");
chdir "$dir";

if (! -f "$dir/keydir/redmine.pub") {
    open ($fh, "<", "$dir/conf/gitolite.conf");
    my @lines = <$fh>;
    close $fh;
    open ($fh, ">", "$dir/conf/gitolite.conf");
    my $inadmin;
    foreach my $line (@lines) {
        chomp $line;
        if (!$inadmin && $line =~ /^repo\s*gitolite-admin/) {
            $inadmin = 1;
        } elsif ($inadmin && $line =~ /RW\+/) {
            $line .= ' redmine' unless ($line =~ /redmine/);
            $inadmin = 0;
        }
        print $fh "$line\n";
    }
    close $fh;
    system("sudo -u redmine cat /var/lib/redmine/.ssh/id_rsa.pub > $dir/keydir/redmine.pub");
    system("git add conf/gitolite.conf keydir/redmine.pub");
    system("git commit --author='git on $hostname <git\@$hostname>' -m 'Add redmine to gitolite-admin repo'");
    system("gitolite push");
}
chdir "/tmp";
