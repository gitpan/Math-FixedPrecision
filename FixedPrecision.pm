#!/usr2/local/bin/perl
#
# PROGRAM:	Math::FixedPrecision.pm	# - 04/26/00 9:10:AM
# PURPOSE:	Perform precise decimal calculations without floating point
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

require Exporter;
require Math::BigInt;
use AutoLoader qw(AUTOLOAD);
use overload 	'+'		=>	\&add,
				'-'		=>	\&subtract,
				'*'		=>	\&multiply,
				'/'		=>	\&divide,
				'<=>'	=>	\&spaceship,
                '""'	=>	\&stringify,
				'0+'	=>	\&numify,
				'abs'	=>	\&absolute,
				'bool'	=>	\&boolean,
				;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $PACKAGE);

@ISA = qw(Exporter Math::BigInt);

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
$VERSION = '0.03';
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
	$value =~ tr/0-9.-//cd;		# Clean out non-numeric characters

	# Normalize the number to 1234567.890
	if ( ( $radix = length($value) - index($value,'.') - 1 ) != length($value) )	# Already has a decimal
	{
		$value =~ tr/0-9-//cd;		# Strip the decimal
		if ( $radix <= $decimal )	# higher precision overrides actual
		{
			$value .= '0' x ( $decimal - $radix );
			$radix  = $decimal;
		}
		elsif ( $decimal )          # Too many decimal places 
		{
			$radix = length($value) - $radix + $decimal;
			my $remainder = substr( $value, $radix, 1 );
			$value = substr( $value, 0, $radix );
			if ( $remainder >= 5 )
			{
				$value += 1;
			}
			$radix = 0;		# force the use of the asserted decimal 
		}
	}
	else 
	{
		$radix  = undef;			# infinite precision
		$value .= '0' x $decimal;	# Has no decimal to start with (but one may have been specified)
	}

	$self->{VAL} = Math::BigInt->new($value);
	if ( defined $radix )
	{
		$self->{RADIX} = $radix;
	}
	elsif ( defined $decimal )
	{
		$self->{RADIX} = $decimal;
	}
	else 
	{
		$self->{RADIX} = undef;
	}
	
	return $self;
}	##new

############################################################################
sub _new		#05/10/99 5:06:PM
				# only use for values already offset by radix
############################################################################

{
	my $proto  = shift;
	my $class  = ref($proto) || $proto;
	my $parent = ref($proto) && $proto;

	my $self = bless {}, $PACKAGE;

	my $value = shift;
	my $radix = shift;
	$self->{VAL}	= Math::BigInt->new($value);
	$self->{RADIX}	= $radix;
	return $self;
}	##new_int

############################################################################
sub add		#05/10/99 5:00:PM
############################################################################

{
	my($oper1,$oper2,$inverted) = @_;
	my ($newop1,$newop2);

	unless ( ref $oper2 )	# Oops, we've got a regular number here
	{
		$oper2 = $PACKAGE->new($oper2);
		unless ( defined $oper2->{RADIX} )	# no decimal place defined
		{
			$oper2->{VAL}	*= 10**$oper1->{RADIX};	# make just as accurate as other term
			$oper2->{RADIX}  = $oper1->{RADIX};
		}
	}

	unless ( defined $oper1->{RADIX} )	# no decimal place defined
	{
		if ( defined $oper2->{RADIX} )
		{
			$oper1->{VAL}	*= 10**$oper2->{RADIX};	# make just as accurate as other term
			$oper1->{RADIX}  = $oper2->{RADIX};
		}
	}
	
	if ( $oper1->{RADIX} < $oper2->{RADIX} )	# need to reduce the precision for calc
	{
		$newop1 = $PACKAGE->new($oper2,$oper1->{RADIX});	# do no harm, operate on copy
		$newop2 = $PACKAGE->_new($oper1->{VAL} + $newop1->{VAL},$oper1->{RADIX});
	}
	elsif ( $oper1->{RADIX} > $oper2->{RADIX} )	# need to reduce the precision for calc
	{
		$newop1 = $PACKAGE->new($oper1,$oper2->{RADIX});	# do no harm, operate on copy
		$newop2 = $PACKAGE->_new($oper2->{VAL} + $newop1->{VAL},$oper2->{RADIX});
	}
	else	# same precision, don't do anything 
	{
		$newop2 = $PACKAGE->_new($oper1->{VAL} + $oper2->{VAL}, $oper1->{RADIX} );
	}
	return $newop2;
}	##add


############################################################################
sub subtract		#05/10/99 5:05:PM
############################################################################

{
	my($oper1,$oper2,$inverted) = @_;
	my ($newop1,$newop2);

	unless ( ref $oper2 )	# Oops, we've got a regular number here
	{
		$oper2 = $PACKAGE->new($oper2);
		unless ( defined $oper2->{RADIX} )	# no decimal place defined
		{
			$oper2->{VAL}	*= 10**$oper1->{RADIX};	# make just as accurate as other term
			$oper2->{RADIX}  = $oper1->{RADIX};
		}
	}
	
	unless ( defined $oper1->{RADIX} )	# no decimal place defined
	{
		if ( defined $oper2->{RADIX} )
		{
			$oper1->{VAL}	*= 10**$oper2->{RADIX};	# make just as accurate as other term
			$oper1->{RADIX}  = $oper2->{RADIX};
		}
	}
	
	if ( $inverted )	# swap terms so I don't need to do this testing for every step
	{
		$newop1 = $oper2;
		$oper2	= $oper1;
		$oper1	= $newop1;
	}
	if ( $oper1->{RADIX} < $oper2->{RADIX} )	# need to reduce the precision for calc
	{
		$newop1 = $PACKAGE->new($oper2, $oper1->{RADIX});	# do no harm, operate on copy
		$newop2 = $PACKAGE->_new($oper1->{VAL} - $newop1->{VAL}, $oper1->{RADIX});
	}
	elsif ( $oper1->{RADIX} > $oper2->{RADIX} )	# ditto
	{
		$newop1 = $PACKAGE->new($oper1,$oper2->{RADIX});	# do no harm, operate on copy
		$newop2 = $PACKAGE->_new($newop1->{VAL} - $oper2->{VAL}, $oper2->{RADIX});
	}
	else	# same precision, don't do anything
	{
		$newop2 = $PACKAGE->_new($oper1->{VAL} - $oper2->{VAL}, $oper1->{RADIX});
	}
	return $newop2;
}	##subtract


############################################################################
sub multiply		#05/10/99 5:12:PM
############################################################################

{
	my($oper1,$oper2,$inverted) = @_;
	my $tempval;

	unless ( ref $oper2 )
	{
		$oper2 = $PACKAGE->new( $oper2 );
		unless ( defined $oper2->{RADIX} )	# no decimal place defined
		{
			$oper2->{VAL}	*= 10**$oper1->{RADIX};	# make just as accurate as other term
			$oper2->{RADIX}  = $oper1->{RADIX};
		}
	}

	unless ( defined $oper1->{RADIX} )	# no decimal place defined
	{
		if ( defined $oper2->{RADIX} )
		{
			$oper1->{VAL}	*= 10**$oper2->{RADIX};	# make just as accurate as other term
			$oper1->{RADIX}  = $oper2->{RADIX};
		}
	}

	$tempval = $oper1->{VAL} * $oper2->{VAL};
	if ( $oper1->{RADIX} < $oper2->{RADIX})	# Need to propagate the lesser accuracy
	{
		$tempval = ($tempval + 10**$oper2->{RADIX}/2 ) / 10**$oper2->{RADIX};	# Round appropriately
		return $PACKAGE->_new( $tempval, $oper1->{RADIX} );
	}
	elsif ( $oper1->{RADIX} >= $oper2->{RADIX} and defined $oper1->{RADIX} )
	{
		$tempval = ($tempval + 10**$oper1->{RADIX}/2 ) / 10**$oper1->{RADIX};	# Round appropriately
		return $PACKAGE->_new( $tempval, $oper2->{RADIX} );
	}
	else # both terms have undef precision (integers); no need to round
	{
		return $PACKAGE->_new( $tempval, undef );
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
		$oper2 = $PACKAGE->new($oper2);
		unless ( defined $oper2->{RADIX} )	# no decimal place defined
		{
			$oper2->{VAL}	*= 10**$oper1->{RADIX};	# make just as accurate as other term
			$oper2->{RADIX}  = $oper1->{RADIX};
		}
	}

	unless ( defined $oper1->{RADIX} )	# no decimal place defined
	{
		if ( defined $oper2->{RADIX} )
		{
			$oper1->{VAL}	*= 10**$oper2->{RADIX};	# make just as accurate as other term
			$oper1->{RADIX}  = $oper2->{RADIX};
		}
	}

	if ( $inverted )
	{
		# need to inflate the numerator to make sure we still have enough decimal places 
		$tempval = ( $oper2->{VAL} * 10**($oper1->{RADIX} + $oper2->{RADIX}) ) / $oper1->{VAL};
		if ( $oper2->{RADIX} < $oper1->{RADIX})	# Need to propagate the lesser accuracy
		{
			$round = $oper2->{RADIX} * 2 - $oper2->{RADIX};	# Hmm, look at this again
			$tempval = ($tempval + 10**$round/2 ) / 10**$round if $round > 0;	# Round appropriately
			return $PACKAGE->_new( $tempval,$oper2->{RADIX} );
		}
		elsif ( $oper2->{RADIX} >= $oper1->{RADIX} and defined $oper2->{RADIX} )
		{
			$round = $oper2->{RADIX} * 2 - $oper1->{RADIX};	# Hmm, look at this again
			$tempval = ($tempval + 10**$round/2 ) / 10**$round if $round > 0;	# Round appropriately
			return $PACKAGE->_new( $tempval,$oper1->{RADIX} );
		}
		else # both terms have undef precision (integers); no need to round
		{
			return $PACKAGE->_new( $tempval, undef );
		} 
	}
	else 
	{
		# need to inflate the numerator to make sure we still have enough decimal places 
		$tempval = ( $oper1->{VAL} * 10**($oper2->{RADIX} + $oper1->{RADIX}) ) / $oper2->{VAL};
		if ( $oper1->{RADIX} < $oper2->{RADIX})	# Need to propagate the lesser accuracy
		{
			$round = $oper1->{RADIX} * 2 - $oper1->{RADIX};	# Hmm, look at this again
			$tempval = ($tempval + 10**$round/2 ) / 10**$round if $round > 0;	# Round appropriately
			return $PACKAGE->_new( $tempval,$oper1->{RADIX} );
		}
		elsif ( $oper1->{RADIX} >= $oper2->{RADIX} and defined $oper1->{RADIX} )
		{
			$round = $oper1->{RADIX} * 2 - $oper2->{RADIX};	# Hmm, look at this again
			$tempval = ($tempval + 10**$round/2 ) / 10**$round if $round > 0;	# Round appropriately
			return $PACKAGE->_new( $tempval,$oper2->{RADIX} );
		}
		else # both terms have undef precision (integers); no need to round
		{
			return $PACKAGE->_new( $tempval, undef );
		} 
	}
}	##divide

############################################################################
sub spaceship		#05/10/99 3:48:PM
############################################################################

{
	my($oper1,$oper2,$inverted) = @_;
	
	unless ( ref $oper2 )
	{
		$oper2 = $PACKAGE->new($oper2);
	}

	my $sgn = $inverted ? -1 : 1;

	# need to selectively inflate both terms to test equality
	return $sgn * ( ($oper1->{VAL} * 10**$oper2->{RADIX}) <=> ($oper2->{VAL} * 10**$oper1->{RADIX}) );
	
}	##spaceship

############################################################################
sub stringify		#05/10/99 3:52:PM
############################################################################

{
	my $self  = shift;
	my $value = abs($self->{VAL}) + 0;
	my $neg   = $self->{VAL} < 0 ? 1 : 0; 
	($value = reverse "$value") =~ s/\+//;
	substr($value,$self->{RADIX},0) = "." if $self->{RADIX};
	$value = reverse $value;
	return "$value";
}	##stringify

############################################################################
sub numify		#05/11/99 12:02:PM
############################################################################

{
	my $self = shift;
	return ( ($self->{VAL} ) / 10**$self->{RADIX} ); # Round appropriately + 10**$self->{RADIX}/2 
}	##numify

############################################################################
sub absolute		#06/15/99 4:47:PM
############################################################################

{
	my $self = shift;
	return $PACKAGE->_new( abs($self->{VAL}), $self->{RADIX} );
}	##absolute

############################################################################
sub boolean		#06/28/99 9:47:AM
############################################################################

{
    my($object) = @_;
    my($result);

    eval
    {
        $result = $object->{VAL}->is_empty();
    };
    return(! $result);
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
data does not consist solely of integers.  This module is designed to operate 
completely overload all standard math functions.  The module takes care of all 
conversion and rounding automatically.  For purposes of this module, 5 - 9 are 
rounded up to the next higher value and 0 - 4 are rounded down.

This module is not a replacement for Math::BigFloat, rather it serves a similar
but slightly different purpose.  By strictly limiting precision automatically,
this module operates slightly more natually than Math::BigFloat, when dealing
with floating point numbers of limited accuracy.  Math::FixedPrecision does not
handle exponential notation, whereas Math::BigFloat can unintentially inflate
the accuracy of a calculation.

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

Math::BigInt

=cut
