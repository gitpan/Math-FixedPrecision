#!/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..26\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::FixedPrecision;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my ($number, $newnumber, $thirdnbr);

unless ( $number = Math::FixedPrecision->new(12.346) )
{
	print "not ";
}
print "ok 2\n";

$number = 2.95 + $number;
unless ( "$number" eq "15.30" )	# has to have that trailing 0
{
	print "not ";
}
print "ok 3\n";

$newnumber = Math::FixedPrecision->new(1.253);
$thirdnbr = $number - $newnumber;

unless ( $thirdnbr == 14.05 )
{
	print "not ";
}
print "ok 4\n";

$number *= 100.125;
unless ( $number == 1531.91 )
{
	print "not ";
}
print "ok 5\n";

$number = Math::FixedPrecision->new(1000.1);
$number /= 99.1234;
unless ( $number == 10.1 )
{
	print "not ";
}
print "ok 6\n";

$number = Math::FixedPrecision->new(1000.1234);
$number /= 99.4;
unless ( $number == 10.1 )
{
	print "not ";
}
print "ok 7\n";

$number = Math::FixedPrecision->new(9.95);
$number /= 2;	# 2 is internally promoted to 2.00
unless ( $number == 4.97 )	# note the even rounding!
{
	print "not ";
}
print "ok 8\n";

unless ( $number < 5.0 )
{
	print "not ";
}
print "ok 9\n";

unless ( 1.1 < $newnumber )
{
	print "not ";
}
print "ok 10\n";

unless ( $newnumber < $number )
{
	print "not ";
}
print "ok 11\n";

unless ( $number )
{
	print "not ";
}
print "ok 12\n";

$number = Math::FixedPrecision->new(10);
$newnumber = $number * 2;
unless ( $newnumber == 20 )
{
	print "not "
}

print "ok 13\n";

$newnumber = $number / 3;
unless ( $newnumber == 3 )
{
	print "not "
}

print "ok 14\n";

$number = Math::FixedPrecision->new("0.10");
$newnumber = $number * 200;
unless ( $newnumber == 20 )
{
	print "not "
}

print "ok 15\n";

unless ( "$number" eq "0.10" )
{
	print "not "
}

print "ok 16\n";

$number = Math::FixedPrecision->new("0.0");
unless ( "$number" eq "0.0" )
{
	print "not "
}

print "ok 17\n";

$number = Math::FixedPrecision->new(12.345,2);
unless ( $number == 12.35 )
{
	print "not ";
}
print "ok 18\n";

$number= new Math::FixedPrecision(1.0,100);
$newnumber= new Math::FixedPrecision(0.0,100);

unless ( $newnumber < $number )
{
	print "not ";
}
print "ok 19\n";

unless ( $newnumber < 2.0 )
{
	print "not ";
}
print "ok 20\n";

$number= new Math::FixedPrecision(7500);
$newnumber= new Math::FixedPrecision(16.95);

unless ( $newnumber < $number )
{
	print "not ";
}
print "ok 21\n";

$number= new Math::FixedPrecision(14.673);
$newnumber= new Math::FixedPrecision(2.6);

if ( $newnumber > $number )
{
	print "not ";
}
print "ok 22\n";

unless ( $number == 14.673 )
{
	print "not ";
}
print "ok 23\n";	#fnord

$newnumber= new Math::FixedPrecision(2);
if ( "$newnumber" ne "2" )
{
	print "not ";
}
print "ok 24\n";

$newnumber= new Math::FixedPrecision(.2);
if ( "$newnumber" ne "0.2" )
{
	print "not ";
}

print "ok 25\n";

$newnumber= new Math::FixedPrecision(12345.6789,0);
if ( "$newnumber" ne "12346" )
{
	print "not ";
}

print "ok 26\n";	# Thanks to Les Howard <les@lesandchris.com> for this test
