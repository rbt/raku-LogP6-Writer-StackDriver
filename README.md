# NAME

**LogP6::Writer::StackDriver** - writer implementation for local `stackdriver` logging

# SYNOPSIS

Useful for logging within the Google Cloud environment where fluentd will pickup logs
and feed them into StackDriver.

Use of this module ensures your messages are treated as single entries (no multi-line issues)
and enables use of triggers/calculations on special fields via MDC.

# CONFIGURATION

You can configure the writer from code by instantiating object of
`LogP6::WriterConf::StackDriver` class. It takes the following parameters:

- `name` - name of the writer configuration
- `handle` - location to write the json formatted log lines; STDOUT by default.
- `use-mdc` - boolean property. Enabled by default. All content of LogP6 `MDC`
will be passed to `stackdriver` as json fields.
- `use-mdc-cro` - boolean property. Enabled by default. Will look for and use the
CRO request/response objects in the MDC information to fill out various HTTP related
fields including `requestMethod`, `requestURL`, `userAgent`, `referer`, `remoteIp`,
and `status`.
- `mdc-key-cro-request` - string property. `cro-request` by default. Tells the logger
which field may provide the CRO request object.
- `mdc-key-cro-response` - string property. `cro-response` by default. Tells the logger which
field may provde the CRO response object.
- `use-source-location` - boolean property, True by default. Will include the source
location in the log entry. Use of this functionalty may slow down your porgram as it requires a `callframe` call
for each log entry.

# EXAMPLE

```perl6
use LogP6 :configure;   # use library in configure mode
use LogP6::WriterConf::StackDriver;
use Cro::HTTP::Router;

my $sd = LogP6::WriterConf::StackDriver.new(
  :handle($*ERR), # Change to use STDERR
  :name<audit>

  use-source-location => False,  # Disable source location

  mdc-key-cro-request => 'webapp-request',
);

cliche(
  :name<cl>,
  :matcher<audit>,
  grooves => ( writer($sd), filter(:level($debug)) ) # Debug level to $sd
);

my $app = route {
  get -> 'healthz' {

    # Note, only that instance of $log will have the MDC information. Consider creating
    # a context object for the request and passing it along the work pipeline.
    my $log = get-logger('audit');
    $log.mdc-put('webapp-request', request());
    $log.debug('Request for healthz');

    content 'text/plain', 'READY';
  }
}

$!cro-service = Cro::HTTP::Server.new(:host<0.0.0.0>, :port<10000>, :$app);
$!cro-service.start;
```

# AUTHOR

Rod Taylor <rbt@cpan.org>

Source can be located at:
[github](https://github.com/rbt/raku-LogP6-Writer-StackDriver). Comments and
Pull Requests are welcome.

# COPYRIGHT AND LICENSE

Copyright 2020 Rod Taylor

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.
