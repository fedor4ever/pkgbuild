#!/usr/bin/perl

use strict;
use Getopt::Long;
use File::Copy;
use File::Spec;

my $username = "admin";
my $password = "admin";
my $host;
my $schedule;
my $host_drop_path;
my $local_drop_path;
my $local_test_pkg;
my $help;

sub usage($);
sub help();
sub usage_error();

my %optmap = (  'host' => \$host,
			    'local-test-pkg' => \$local_test_pkg,
				'host-drop-path' => \$host_drop_path,
				'local-drop-path' =>\$local_drop_path,
				'username' => \$username,
				'password' => \$password,
				'schedule' => \$schedule,
                'help' => \$help);

GetOptions(\%optmap,
          'host=s',
          'local-test-pkg=s',
          'host-drop-path=s',
          'local-drop-path=s',
          'username=s',
          'password=s',
          'schedule=s',
          'help!') 
          or usage_error();

if ($help) {
	help();
}

usage_error(), unless (defined($host) && defined($local_test_pkg) && defined($local_drop_path) && defined($host_drop_path));

my $cscript_help = `cscript /?`;
die("Need command \"cscript\". Not in found"), if ($?);
die("Need VB script wshTestRunX.vbs. Not found"), unless ( -f "wshTestRunX.vbs");
die("Test drop path \"$local_drop_path\" not found"), unless ( -d "$local_drop_path");

my ($vol,$dir,$pkg);
my $local_test_drop;
my $host_test_drop;

if ($local_test_pkg =~ /^\.\.\.(.+)/ ) {
    $pkg = $1;
    $local_test_drop = File::Spec->catfile($local_drop_path,$pkg);
    die("Test package file \"$local_test_drop\" not found"), unless ( -f "$local_test_drop");        
}
else {
    die("Test package file \"$local_test_pkg\" not found"), unless ( -f "$local_test_pkg");
    ($vol,$dir,$pkg) = File::Spec->splitpath($local_test_pkg);
    $local_test_drop = File::Spec->catfile($local_drop_path,$pkg);
    my $lc_local_test_drop = lc($local_test_drop);
    my $lc_local_test_pkg = lc($local_test_pkg);    
    if ("$lc_local_test_drop" ne "$lc_local_test_pkg") {
        if (unlink($local_test_drop) == 0) {
            die("Can't delete stale testdrop \"$local_test_drop\". $!");
        }
        else {
            print("A stale testtop \"$local_test_drop\" existed. Deleted\n");
        }
        copy("$local_test_pkg","$local_test_drop")
            or die("Cannot copy \"$local_test_pkg\" -> \"$local_test_drop\". $!");
    }    
}
$host_test_drop = File::Spec->catfile($host_drop_path,$pkg);

$ENV{'ats3.host'} = $host;
$ENV{'ats3.pathToDrop'} = $host_test_drop;
$ENV{'ats3.username'} = $username;
$ENV{'ats3.password'} = $password;
$ENV{'ats3.schedule'} = $schedule, if defined($schedule);
system("cscript wshTestRunX.vbs");
die("\nTest drop failed: $!"), if ($?);
print("\nTest drop done");

exit 0;

sub usage($)
{
    my $error = shift;
    my $fh = $error == 0 ? *STDOUT : *STDERR;
    print $fh "ats3_testdrop.pl\n" .
            "Send a test drop to an ATS3 server for execution\n" .
            "usage:\n" .
            "  ats3_testdrop.pl --help\n" .
            "  ats3_testdrop.pl --host=HOSTNAME --local-test-pkg=PKGFILE --local-drop-path=LOCALPATH " .
                " --host-drop-path=HOSTPATH " .
                "[--username=ATS3USERNAME] [--password=ATS3PASSWORD] [--schedule=DD.MM.YYYY-HH:MM]\n" .
            "options:\n" .
            "  --help                        Display this help and exit\n" .
            "  --host=HOSTAME                HOSTNAME is ATS3 server\n" .
            "  --local-test-pkg=PKGFILE      PKGFILE is the test package.\n" .
            "                                If PKGFILE begins "..." a filename in LOCALPATH is assumed\n" .
            "  --local-drop-path=LOCALPATH   Path to local directory where PKGFILE will be dropped\n" .            
            "  --host-drop-path=HOSTPATH     Host directory that is mapped to LOCALPATH.\n" .
            "                                Must agree with the properties of the registered device that the test package nominates\n" .
            "  --username=ATS3USERNAME       ATS3 user to whome the test will belong. Default=admin\n" .
            "  --password=ATS3PASSWORD       Password of ATS3 user. Default=admin\n" .
            "  --schedule=DD.MM.YYYY-HH:MM   Date-time at which test is to run. Default=as soon as possible\n";
    exit $error;            
}

sub help()
{
    usage(0);
}

sub usage_error()
{
    usage(1);
}             

# EOF
   