use strict; use warnings;

package URI::Signature::Tiny;

our $VERSION = '1.000';

use Digest::SHA ();
use Carp ();
use Scalar::Util ();

my @defaults = (
	sort_params   => 1,
	recode_base64 => 1,
	after_sign    => sub { Carp::croak( 'No after_sign callback specified' ) },
	before_verify => sub { Carp::croak( 'No before_verify callback specified' ) },
	function      => \&Digest::SHA::hmac_sha256_base64,
);

sub new {
	my $class = shift;
	my $self = bless { @defaults, @_ }, $class;
	Carp::croak( "Missing secret for $class" ) unless defined $self->{'secret'};
	$self;
}

sub signature {
	my ( $self, $uri ) = ( shift, @_ );

	Carp::croak( 'Cannot compute the signature of an undefined value' ) unless defined $uri;

	$uri = $uri->isa( 'URI::WithBase' ) ? $uri->abs->as_string : $uri->as_string
		if Scalar::Util::blessed( $uri );

	$uri =~ m[ \A [^?#]* \? ]xgc and $uri =~ s[ \G ([^#]+) ]{
		my @qp = split /[&;]/, "$1";
		join ';', $self->{'sort_params'} ? sort @qp : @qp;
	}xe;

	my $sig = $self->{'function'}->( $uri, $self->{'secret'} );

	$sig =~ s/=+\z//, $sig =~ y{+/}{-_} if $self->{'recode_base64'};

	$sig;
}

sub sign {
	my ( $self, $uri ) = ( shift, @_ );
	$self->{'after_sign'}->( $uri, $self->signature( $uri ) );
}

sub verify {
	my $self = shift;
	my ( $uri, $sig ) = $self->{'before_verify'}->( @_ );
	$sig eq $self->signature( $uri );
}

1;