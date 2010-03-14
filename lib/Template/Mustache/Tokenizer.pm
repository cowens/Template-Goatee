package Template::Mustache::Tokenizer;

use strict;
use warnings;

use Carp;

=head1 NAME

Template::Mustache::Tokenizer - tokenizer for Mustache

=head1 VERSION

Version 20100313

=cut

our $VERSION = 20100313;

=head1 SYNOPSIS

Turn a string that holds a Mustache template into tokens for a parser.

    use Template::Mustache::Tokenizer;

    my $string = "This is a {{name}} tokenizer";

    my $tokenizer = Template::Mustache::Tokenizer->new($string)
        or die "could not tokenize [$string]\n";

    while (defined(my $token = $tokenizer->next)) {
        print "token: $token\n";
    }

=head1 USEFUL VARIABLES

=head2 $Template::Mustache::Tokenizer::comment 

matches a comment token (e.g. {{! this is ignored }}

=head2 $Template::Mustache::Tokenizer::partial 

matches a partial token (e.g. {{>template_to_load}})

=head2 $Template::Mustache::Tokenizer::enum_start 

matches the start of a  boolean or enumerable section (e.g. {{#optional_or_list}})

=head2 $Template::Mustache::Tokenizer::enum_stop 

matches the end of a boolean or enumerable section (e.g. {{/optional_or_list}})

=head2 $Template::Mustache::Tokenizer::variable 

matches a variable token (e.g. {{var}})

=head2 $Template::Mustache::Tokenizer::unescaped 

matches an unescaped variable token (e.g. {{{var}}})

=cut;

our $start_escaped = qr/ (?<! \{ ) \{{2} (?! \{ )/x; #not a {, two {s, not a {
our $end_escaped   = qr/ (?<! } ) }{2} (?! } )   /x; #not a }, two }s, not a }
our $start         = qr/ \{{3}                   /x; # three {s in a row
our $end           = qr/ }{3}                    /x; # three }s in a row

our $comment         = qr/ \G $start_escaped !   .*?    $end_escaped /x;
our $partial         = qr/ \G $start_escaped >   .*?    $end_escaped /x;
our $enum_start      = qr/ \G $start_escaped [#] .*?    $end_escaped /x;
our $enum_stop       = qr{ \G $start_escaped /   .*?    $end_escaped }x;
our $variable        = qr/ \G $start             [^{}]+ $end         /x;
our $escaped         = qr/ \G $start_escaped     [^{}]+ $end_escaped /x;
our $text            = qr/ \G [^{]+ /x;
our $curly           = qr/ \G \{ (?! \{ ) /x;

our $tokenizer = qr/
	$comment   | $partial  | $enum_start |
	$enum_stop | $variable | $escaped    |
	$text      | $curly
/x;

=head1 METHODS

=head2 new(STRING)

Creates a new Template::Mustache::Tokenizer oject that will tokenize the
template stored in STRING

=cut

sub new {
	my $class = shift;
	my $self  = {
		_buf => shift,
	};
	return bless $self, $class;
}

=head2 next()

Returns the next token.  Returns undef when there are no more tokens left.

=cut

sub next {
	my $self = shift;
	our $tokenizer;
	return $1 if $self->{_buf} =~ /($tokenizer)/g;
	return undef unless pos $self->{_buf};
	croak "I don't undrestand what is going on around character ", 
		(pos $self->{_buf}), "of the template\n";
}

1;
