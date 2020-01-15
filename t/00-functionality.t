use Test;

use lib 'lib';
use lib './t/resources/00-config-file';
use LogP6 :configure;
use LogP6::WriterConf::StackDriver;
use IOString;
use JSON::Fast;

plan 2;

sub foo($log) {
	$log.warn('boom');
	return callframe(0);
}

my $handle1 = IOString.new();
my $handle2 = IOString.new();

# Use-mdc enabled by default.
writer(LogP6::WriterConf::StackDriver.new(
	:name<stackdriver-1>, handle => $handle1,
));

writer(LogP6::WriterConf::StackDriver.new(
	:name<stackdriver-2>, handle => $handle2, use-mdc => False,
));
cliche(:name<stackdriver-1>, :matcher<stackdriver-1>, grooves => ('stackdriver-1', level($trace)));
cliche(:name<stackdriver-2>, :matcher<stackdriver-2>, grooves => ('stackdriver-2', level($trace)));

my $log;
my $frame;

$log = get-logger('stackdriver-1');
$log.mdc-put('OBJ', 'value');
$log.mdc-put('VAL', 'obj');
$frame = foo($log);

$log = get-logger('stackdriver-2');
$log.mdc-put('OBJ', 'value');
$log.mdc-put('VAL', 'obj');
$frame = foo($log);

subtest {
	my $h1json;
	lives-ok {
		$h1json = from-json($handle1.Str);
	}, 'Output is json';
	is $h1json<OBJ>, 'value', 'Has MDC variable OBJ';
	is $h1json<VAL>, 'obj', 'Has MDC variable VAL';
	is $h1json<message>, 'boom', 'Has message';
	is $h1json<severity>, 'warn', 'Has severity';
	ok $h1json<timestamp>:exists, 'Has timestamp';
}, 'Writer with MDC';

subtest {
	my $h2json;
	lives-ok {
		$h2json = from-json($handle2.Str);
	}, 'Output is json';
	ok not $h2json<OBJ>:exists, 'Does not have MDC variable OBJ';
	ok not $h2json<VAL>:exists, 'Does not have MDC variable VAL';
	is $h2json<message>, 'boom', 'Has message';
	is $h2json<severity>, 'warn', 'Has severity';
	ok $h2json<timestamp>:exists, 'Has timestamp';
}, 'Writer without MDC';

done-testing;

