#!/usr2/local/bin/perl -w
#
# PROGRAM:	Math::FixedPrecision.pm	# - 04/26/00 9:10:AM
# PURPOSE:	Perform precise decimal calculations without floating point errors
#
#------------------------------------------------------------------------------
#   Copyright (c) 2000 John Peacock
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,
#   with the exception that it cannot be placed on a CD-ROM or similar media
#   for commercial distribution without the prior approval of the author.
#------------------------------------------------------------------------------
eval 'exec /usr2/local/bin/perl -S $0 ${1+"$@"}'
    if 0;

package Math::FixedPrecision;

require 5.005_02;
use strict;

use Exporter;
use Math::BigFloat(0.01);
use overload 	'+'		=>	\&add,
				'-'		=>	\&subtract,
				'*'		=>	\&multiply,
				'/'		=>	\&divide,
				'<=>'	=>	\&spaceship,
				'cmp'	=>	\&compare,
                '""'	=>	\&stringify,
				'0+'	=>	\&numify,
				'abs'	=>	\&absolute,
				'bool'	=>	\&boolean,
				;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $PACKAGE);

@ISA = qw(Exporter Math::BigFloat);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::FixedPrecision ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '0.12';
$PACKAGE = 'Math::FixedPrecision';

# Preloaded methods go here.
############################################################################
sub new		#04/20/00 12:08:PM
############################################################################
{
	my $proto  = shift;
	my $class  = ref($proto) || $proto;
	my $parent = ref($proto) && $proto;

	my $self = bless {}, $class;

	my $value	= shift || 0;	# Set to 0 if not provided
	my $decimal	= shift;
	my $radix	= 0;

	# Store the floating point value
	$self->{VAL} = Math::BigFloat->new($value);

	# Normalize the number to 1234567.890
	if ( ( $radix = length($value) - index($value,'.') - 1 ) != length($value) )	# Already has a decimal
	{
		if ( defined $decimal and $radix <= $decimal )	# higher precision overrides actual
		{
			$radix  = $decimal;
		}
		elsif ( $decimal )          # Too many decimal places 
		{
			my $var = $self->{VAL}->ffround(-1 * $decimal);
			$self->{VAL} = new Math::BigFloat $var;
			$radix = 0;		# force the use of the asserted decimal 
		}
	}
	else 
	{
		$radix  = 0;			# infinite precision
	}

	if ( $radix )
	{
		$self->{RADIX} = $radix;
	}
	elsif ( defined $decimal )
	{
		$self->{RADIX} = $decimal;
	}
	else 
	{
		$self->{RADIX} = 0;
	}
	
	return $self;
}	##new

############################################################################
sub _new		#07/27/00 4:02:PM
############################################################################

{
	my $proto  = shift;
	my $class  = ref($proto) || $proto;
	my $parent = ref($proto) && $proto;

	my $self = bless {}, $class;

	my $value = shift;
	my $radix = shift;
	$self->{VAL}	= new Math::BigFloat $value->ffround(-$radix);
	$self->{RADIX}	= $radix;
	return $self;
}	##_new

############################################################################
sub add		#05/10/99 5:00:PM
############################################################################

{
	my($oper1,$oper2,$inverted) = @_;
	my ($newop);

	unless ( ref $oper2 )	# Oops, we've got a regular number here
	{
		$oper2 = $oper1->new($oper2);	# use the same type as other var
		unless ( $oper2->{RADIX} )	# no decimal place defined
		{
			$oper2->{RADIX}  = $oper1->{RADIX};
		}
	}

	unless ( $oper1->{RADIX} )	# no decimal place defined
	{
		if ( $oper2->{RADIX} )
		{
			$oper1->{RADIX}  = $oper2->{RADIX};
		}
	}
	
	if ( $oper1->{RADIX} <= $oper2->{RADIX} )	# need to reduce the precision for calc
	{
		$newop = $oper1->_new($oper1->{VAL} + $oper2->{VAL},$oper1->{RADIX});
	}
	else 
	{
		$newop = $oper1->_new($oper2->{VAL} + $oper1->{VAL},$oper2->{RADIX});
	}
	return $newop;
}	##add


############################################################################
sub subtract		#05/10/99 5:05:PM
############################################################################

{
	my($oper1,$oper2,$inverted) = @_;
	my ($newop);

	unless ( ref $oper2 )	# Oops, we've got a regular number here
	{
		$oper2 = $oper1->new($oper2);	# use the same type as other var
		unless ( $oper2->{RADIX} )	# no decimal place defined
		{
			$oper2->{RADIX}  = $oper1->{RADIX};
		}
	}
	
	unless ( $oper1->{RADIX} )	# no decimal place defined
	{
		if ( $oper2->{RADIX} )
		{
			$oper1->{RADIX}  = $oper2->{RADIX};
		}
	}
	
	if ( $inverted )	# swap terms so I don't need to do this testing for every step
	{
		$newop = $oper2;
		$oper2	= $oper1;
		$oper1	= $newop;
	}

	if ( $oper1->{RADIX} <= $oper2->{RADIX} )	# may need to reduce the precision for calc
	{
		$newop = $oper1->_new($oper1->{VAL} - $oper2->{VAL}, $oper1->{RADIX});
	}
	else
	{
		$newop = $oper1->_new($oper1->{VAL} - $oper2->{VAL}, $oper2->{RADIX});
	}
	return $newop;
}	##subtract


############################################################################
sub multiply		#05/10/99 5:12:PM
############################################################################

{
	my($oper1,$oper2,$inverted) = @_;
	my $tempval;

	unless ( ref $oper2 )
	{
		$oper2 = $PACKAGE->new( $oper2 );	# should NOT be same type
		unless ( $oper2->{RADIX} )	# no decimal place defined
		{
			$oper2->{RADIX}  = $oper1->{RADIX};
		}
	}

	unless ( $oper1->{RADIX} )	# no decimal place defined
	{
		if ( $oper2->{RADIX} )
		{
			$oper1->{RADIX}  = $oper2->{RADIX};
		}
	}

	$tempval = $oper1->{VAL} * $oper2->{VAL};

	if ( $oper1->{RADIX} < $oper2->{RADIX})	# Need to propagate the lesser accuracy
	{
		return $oper1->_new( $tempval, $oper1->{RADIX} );
	}
	else 
	{
		return $oper1->_new( $tempval, $oper2->{RADIX} );
	}
}	##multiply

############################################################################
sub divide		#05/10/99 5:12:PM
############################################################################

{
	my($oper1,$oper2,$inverted) = @_;
	my ($tempval, $round);

	unless ( ref $oper2 )
	{
		$oper2 = $PACKAGE->new( $oper2 );	# should NOT be same type
		unless ( $oper2->{RADIX})	# no decimal place defined
		{
			$oper2->{RADIX}  = $oper1->{RADIX};
		}
	}

	unless ( $oper1->{RADIX} )	# no decimal place defined
	{
		if ( $oper2->{RADIX} )
		{
			$oper1->{RADIX}  = $oper2->{RADIX};
		}
	}

	if ( $inverted )
	{
		$tempval = $oper2->{VAL} / $oper1->{VAL};
	}
	else 
	{
		$tempval = $oper1->{VAL} / $oper2->{VAL};
	}
	
	if ( $oper1->{RADIX} < $oper2->{RADIX})	# Need to propagate the lesser accuracy
	{
		return $oper1->_new( $tempval,$oper1->{RADIX} );
	}
	else # $oper1->{RADIX} >= $oper2->{RADIX}
	{
		return $oper1->_new( $tempval,$oper2->{RADIX} );
	}
}	##divide

############################################################################
sub spaceship		#05/10/99 3:48:PM
############################################################################

{
	my($oper1,$oper2,$inverted) = @_;
	
	unless ( ref $oper2 )
	{
		$oper2 = $oper1->new($oper2);
	}

	my $sgn = $inverted ? -1 : 1;
	return $sgn * ( $oper1->{VAL} <=> $oper2->{VAL} );
	
}	##spaceship

############################################################################
sub compare		#07/05/2000 12:09PM
############################################################################

{
	my($number1,$number2,$inverted) = @_;

	return "$number2" cmp "$number1" if $inverted;
	return "$number1" cmp "$number2";
	
}	##compare

############################################################################
sub stringify		#05/10/99 3:52:PM
############################################################################

{
	my $self  = shift;
	my $decimal = length($self->{VAL}) - index($self->{VAL},'.') - 1;
	my $stringval = "$self->{VAL}";
	if ( $self->{RADIX} > $decimal )
	{
		$stringval .= 0 x ($self->{RADIX} - $decimal);
	}
	if ( $stringval =~ /^\./ )	# if there are no digits to the left of the decimal
	{
		$stringval = "0" . $stringval;
	}
	elsif ( $stringval =~ /^-\./ )	# if there are no digits to the left of the decimal (negative case)
	{
		substr($stringval,1,0) = "0";
	}
	elsif ( $stringval =~ /\.$/ )	# if there are no digits to the right of the decimal
	{
		chop $stringval;
	}
	return $stringval
}	##stringify

############################################################################
sub numify		#05/11/99 12:02:PM
############################################################################

{
	my $self = shift;
	return ( $self->{VAL} + 0 );
}	##numify

############################################################################
sub absolute		#06/15/99 4:47:PM
############################################################################

{
	my $self = shift;
	return $self->_new( abs($self->{VAL}), $self->{RADIX} );
}	##absolute

############################################################################
sub boolean		#06/28/99 9:47:AM
############################################################################

{
    my($object) = @_;
	if ( $object->{VAL} != 0 )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}	##boolean

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Math::FixedPrecision - Decimal Math without Floating Point Errors

=head1 SYNOPSIS

use Math::FixedPrecision;
$height  = Math::FixedPrecision->new(12.362);   # 3 decimal places
$width   = Math::FixedPrecision->new(9.65);     # 2 decimal places
$area    = $height * $width; # area is now 119.29 not 119.2933
$length  = Math::FixedPrecision->new("100.00"); # 2 decimal places
$section = $length / 9; # section is now 11.11 not 11.1111111...

=head1 DESCRIPTION

There are numerous instances where floating point math is unsuitable, yet the
data does not consist solely of integers.  This module is designed to completely 
overload all standard math functions.  The module takes care of all conversion 
and rounding automatically.  Rounding is handled using the IEEE 754 standard
even mode.  This is a complete rewrite to use Math::BigFloat, rather than 
Math::BigInt to handle the underlying math operations.

This module is not a replacement for Math::BigFloat; rather it serves a similar
but slightly different purpose.  By strictly limiting precision automatically,
this module operates slightly more natually than Math::BigFloat when dealing
with floating point numbers of limited accuracy.  Math::BigFloat can 
unintentially inflate the apparent accuracy of a calculation.

Please examine assumptions you are operating under before deciding between this 
module and Math::BigFloat.  With this module the assumption is that your data 
is not very accurate and you do not want to overstate any resulting values; 
with Math::BigFloat, you can completely avoid the rounding problems associated 
with floating point notation.

=head2 new(number[,precision])

The constructor accepts either a number or a string that looks like a number.
But if you want to enforce a specific precision, you either need to pass an
exact string or include the second term.  In other words, all of the following
variables have different precisions:
		
  $var1 = Math::FixedPrecision->new(10); 
          # 10 to infinite decimals
  $var2 = Math::FixedPrecision->new(10,2);
          # 10.00 to 2 decimals
  $var3 = Math::FixedPrecision->new("10.000"); 
          # 10.000 to 3 decimals

All calculations will return a value rounded to the level of precision of
the least precise datum.  A number which looks like an integer (like $var1 
above) has infinite precision (no decimal places).  This is important to note
since Perl will happily truncate all trailing zeros from a number like 10.000 
and the code will get 10 no matter how many zeros you typed.  If you need to 
assert a specific precision, you need to either explicitly state that like 
$var2 above, or quote the number like $var3.  For example:

  $var4 = $var3 * 2; # 20.000 to 3 decimals
  $var5 = Math::FixedPrecision->new("2.00"); 
          # 2.00 to 2 decimals
  $var6 = $var3 * $var 5; 
          # 20.00 to 2 decimals, not 3


=head2 EXPORT
None by default.


=head1 AUTHOR

John Peacock, jpeacock@univpress.com

=head1 SEE ALSO

Math::BigFloat

=cut
