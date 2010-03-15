#!perl

use Test::More tests => 114;

use strict;
use warnings;

BEGIN {
	use_ok 'Template::Mustache::Tokenizer';
}

diag "Testing Template::Mustache::Tokenizer $Template::Mustache::Tokenizer::VERSION, Perl $], $^X";

my @tokens = (
	"{{!comment}}",             "\n",         #1,   2
	"{{>partial}}",             "\n",         #3,   4
	"{{#enum start}}",          "\n",         #5,   6
	"{{/enum stop}}",           "\n",         #7,   8
	"{{variable}}",             "\n",         #9,  10
	"{{{unescaped variable}}}", "\n(text)",   #11, 12

	"{{(= =)}}",                "\n",         #13
	"(!comment)",               "\n",         #14, 15
	"(>partial)",               "\n",         #16, 17
	"(#enum start)",            "\n",         #18, 19
	"(/enum stop)",             "\n",         #20, 21
	"(variable)",               "\n",         #22, 23
	'(&unescaped variable)',    "\n{{text}}", #24, 25

	"(#= =#)",                  "\n",         #26
	"#!comment#",               "\n",         #27, 28
	"#>partial#",               "\n",         #29, 30
	"##enum start#",            "\n",         #31, 32
	"#/enum stop#",             "\n",         #33, 34
	"#variable#",               "\n",         #35, 36
	"#&unescaped variable#",    "\n(text)",   #37, 38
	
	"#{{= =}}#",                "\n",         #39, 40
	"{{!comment}}",             "\n",         #41, 42
	"{{>partial}}",             "\n",         #43, 44
	"{{#enum start}}",          "\n",         #45, 46
	"{{/enum stop}}",           "\n",         #47, 48
	"{{variable}}",             "\n",         #49, 50
	"{{{unescaped variable}}}", "\n#text#",   #51, 52

);
my @types = (
	"comment",            "text",
	"partial",            "text",
	"enum start",         "text",
	"enum stop",          "text",
	"variable",           "text",
	"unescaped variable", "text",

	                      "text",
	"comment",            "text",
	"partial",            "text",
	"enum start",         "text",
	"enum stop",          "text",
	"variable",           "text",
	"unescaped variable", "text",

	                      "text",
	"comment",            "text",
	"partial",            "text",
	"enum start",         "text",
	"enum stop",          "text",
	"variable",           "text",
	"unescaped variable", "text",

	                      "text",
	"comment",            "text",
	"partial",            "text",
	"enum start",         "text",
	"enum stop",          "text",
	"variable",           "text",
	"unescaped variable", "text",
);

my $template = join "", @tokens;

my $t = Template::Mustache::Tokenizer->new($template);

isa_ok $t, "Template::Mustache::Tokenizer";

my $i = 1;
for my $type (@types) {
	my $result = $t->next;
	my $token = shift @tokens;
	push @tokens, $token;
	if ($token =~ /= =/) {
		$token = shift @tokens;
		push @tokens, $token;
	}
	my $style = $t->start . " " . $t->end;

	(my $display = $token) =~ s/\n/\\n/g;

	is $result, $token, $i++ . " token $display with style $style";
}
is scalar $t->next, undef, "end of tokens returns undef";

for my $type (@types) {
	my @a = $t->next;
	my $token = shift @tokens;
	push @tokens, $token;
	if ($token =~ /= =/) {
		$token = shift @tokens;
		push @tokens, $token;
	}
	my $style = $t->start . " " . $t->end;

	(my $display = $token) =~ s/\n/\\n/g;

	is_deeply \@a, [ $token, $type ], "token $display with style $style";
}
{
	my @a = $t->next;
	is scalar @a, 0, "end of tokens returns empty list";
}

my @type_tests = (
	[ comment              => "{{! this is a comment! }}"             ],
	[ partial              => "{{> this is a partial }}"              ],
	[ "enum start"         => "{{# this is an enum start }}"          ],
	[ "enum stop"          => "{{/ this is an enum stop }}"           ],
	[ variable             => "{{  this is a variable }}"             ],
	[ "unescaped variable" => "{{{ this is an unescaped variable }}}" ],
	[ text                 => "this is\ntext"                         ],
);

for my $test (@type_tests) {
	my ($expected, $got) = @$test;
	is $t->type($got), $expected, "testing type $expected";
}

$t = Template::Mustache::Tokenizer->new("{{( = =)}}");
eval {{ $t->next }};
is $@, "delimiters cannot contain whitespace at t/tokenizer.t line 138\n",
	"testing bad set delimiter";
