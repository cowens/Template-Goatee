package Template::Mustache::Tokenizer;

use strict;
use warnings;

use Carp;

=head1 NAME

Template::Mustache::Tokenizer - tokenizer for Mustache

=head1 VERSION

Version 20100313

=cut

our $VERSION = 20100315;

=head1 SYNOPSIS

Turn a string that holds a Mustache template into tokens for a parser.

    use Template::Mustache::Tokenizer;

    my $string = "This is a {{name}} tokenizer";

    my $tokenizer = Template::Mustache::Tokenizer->new($string)
        or die "could not tokenize [$string]\n";

    while (defined(my $token = $tokenizer->next)) {
        #replace unprintable characters with printable versions
        $token =~ s/([\x{0}-\x{1f}\x{7f}])/sprintf "\\x{%x}", ord $1/ge;
        print "token: $token\n";
    }

    while (my ($token, $type) = $tokenizer->next) {
        #replace unprintable characters with printable versions
        $token =~ s/([\x{0}-\x{1f}\x{7f}])/sprintf "\\x{%x}", ord $1/ge;
        print "token '$token' is of type $type\n";
    }

=cut

BEGIN {
	my @accessors = qw/
		comment  partial   enum_start enum_stop
		variable unescaped text       tokenizer
		start    end
	/;
	{
		no strict 'refs';
		for my $accessor (@accessors) {
			*{$accessor} = sub {
				my $self = shift;
				return $self->{"_$accessor"};
			}
		}
	}
}

#FIXME: This could use Perl 5.10's named captures to make parsing
#eaiser.  Right now we have to use an innefficient helper function.
#FIXME: This assumes that we have the full template, I need to work
#on a streaming version.
sub _gen_rules {
	my $self          = shift;
	my ($s, $e) = map { quotemeta } @{$self}{qw/ _start _end /};

	# N.B. order is very important
	my $tokenizer = join "|", (
		($self->{_comment}    = qr{ \G $s !         .+? $e    }xms),
		($self->{_partial}    = qr{ \G $s >         .+? $e    }xms),
		($self->{_enum_start} = qr{ \G $s \#        .+? $e    }xms),
		($self->{_enum_stop}  = qr{ \G $s /         .+? $e    }xms),
		($self->{_unescaped}  = ("$s $e" eq "\\{\\{ \\}\\}")       ?
			                qr{ \G \{{3}        .+? \}{3} }xms :
			                qr{ \G $s &         .+? $e    }xms
		),
		($self->{_variable}   = qr{ \G $s [^!>\#/&] .*? $e    }xms),
		($self->{_text}       = qr{ \G .+? (?= $s | $ )       }xms)
	);
	$self->{_tokenizer}  = qr/$tokenizer/x;
}

=head1 METHODS

=head2 Template::Mustache::Tokenizer->new(STRING)

Creates a new Template::Mustache::Tokenizer oject that will tokenize the
template stored in STRING

=cut

sub new {
	my $class = shift;
	my $self  = {
		_buf   => shift,
		_start => "{{",
		_end   => "}}",
	};

	bless $self, $class;

	$self->_gen_rules;

	return $self;
}

=head2 $tokenizer->next

In scalar context, it returns the next token.  If there are no more tokens then
it returns undef;

In list context, it returns the next token and the token's type.  If there are
no more tokens then it returns an empty list.

=cut

sub next {
	my $self      = shift;
	my $tokenizer = $self->tokenizer;

	unless ($self->{_buf} =~ /($tokenizer)/g) {
		return unless pos $self->{_buf};
		croak "I don't undrestand what is going on around character ", 
			(pos $self->{_buf}), "of the template";
	}

	my $token = $1;
	my $type  = $self->type($token);
	my ($s, $e) = map { quotemeta } @{$self}{qw/ _start _end /}; 

	if ($token =~ /\A$s(.+?)= =(.+?)$e\z/) {
		$self->{_start} = $1;
		$self->{_end}   = $2;

		croak "delimiters cannot contain whitespace"
			if "$self->{_start}$self->{_end}" =~ /\s/;

		$self->_gen_rules;
		if ($self->{_debug}) {
			warn "start is now $self->{_start} (was $s)\n",
			"end   is now $self->{_end}   (was $e)\n";
		}
		return $self->next;
	}

	if (wantarray) {
		return $token, $type if defined $token;
	} else {
		return $token if defined $token;
	}
}

=head2 $tokenizer->type(TOKEN)

Returns a string that identifies the type of the token TOKEN.

Returns undef if TOKEN is not a token.

=cut

sub type {
	my $self  = shift;
	my $token = shift;

	# N.B. order is very important
	return "comment"            if $token =~ /\A$self->{_comment}\z/;
	return "partial"            if $token =~ /\A$self->{_partial}\z/;
	return "enum start"         if $token =~ /\A$self->{_enum_start}\z/;
	return "enum stop"          if $token =~ /\A$self->{_enum_stop}\z/;
	return "unescaped variable" if $token =~ /\A$self->{_unescaped}\z/;
	return "variable"           if $token =~ /\A$self->{_variable}\z/;
	return "text"               if $token =~ /\A$self->{_text}\z/;
	return undef;
}

=head2 $tokenizer->comment 

Returns a regex that matches a comment token (e.g. {{! this is ignored }}.

Note: this regex cannot be cached as it changes while the document is being
tokenized.

=head2 $tokenizer->partial 

Returns a regex that matches a partial token (e.g. {{>template_to_load}}).

Note: this regex cannot be cached as it changes while the document is being
tokenized.

=head2 $tokenizer->enum_start 

Returns a regex that matches the start of a  boolean or enumerable section
(e.g. {{#optional_or_list}}).

Note: this regex cannot be cached as it changes while the document is being
tokenized.

=head2 $tokenizer->enum_stop 

Returns a regex that matches the end of a boolean or enumerable section (e.g.
{{/optional_or_list}}).

Note: this regex cannot be cached as it changes while the document is being
tokenized.

=head2 $tokenizer->variable 

Returns a regex that matches a variable token (e.g. {{var}}).

Note: this regex cannot be cached as it changes while the document is being
tokenized.

=head2 $tokenizer->unescaped 

Returns a regex that matches an unescaped variable token (e.g. {{{var}}}).

Note: this regex cannot be cached as it changes while the document is being
tokenized.

=head2 $tokenizer->start 

Returns the current starting delimiter (default "{{").

Note: this regex cannot be cached as it changes while the document is being
tokenized.

=head2 $tokenizer->end 

Returns the current ending delimiter (default "}}").

Note: this regex cannot be cached as it changes while the document is being
tokenized.

=head2 $tokenizer->tokenizer 

Returns the a regex that can be used to tokenize a string.

Note: this regex cannot be cached as it changes while the document is being
tokenized.

=head1 AUTHOR

Chas. J. Owens IV, C<< <chas.owens at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-mustache at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Mustache>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Mustache


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Mustache>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Mustache>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Mustache>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Mustache/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Chas. J. Owens IV.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

"I don't know how to play the bass.";
