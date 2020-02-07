use LogP6::Writer;

use JSON::Fast;

my constant MAX_LOG_MESSAGE = 1000;

# Based on this logging facility:
# https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry
class LogP6::Writer::StackDriver does LogP6::Writer {
	has IO::Handle:D $.handle is required;
    has Bool $.use-mdc is required;
    has Bool $.use-mdc-cro is required;
    has Str $.mdc-key-cro-request is required;
    has Str $.mdc-key-cro-response is required;
    has Bool $.use-source-location is required;
    has Bool $.pretty = False;

    # Some branch points can be removed via the configuration Class, which Rakudo might optimize away
    # anyway; but the majority of the work needs to be done on a per-log message basis.
    method write($context) {
        # Trim very long messages down. StackDriver doesn't like them very much. The end of
        # stacktraces tends to be less useful than the beginnings, so the end is trimmed.
        my $message = $context.msg;
        if ($message.chars > MAX_LOG_MESSAGE ) {
            $message = $message.substr( 0, MAX_LOG_MESSAGE ) ~ q{…};
        }

        my $struct = {
            category => $context.trait,
            timestamp => $context.date.Str,
            severity  => $context.level,
            message   => $context.msg,
        };

        if $.use-mdc-cro {
            my %http-request;
            my $cro-request = $context.mdc-get($.mdc-key-cro-request) with $.mdc-key-cro-request;
            my $cro-response = $context.mdc-get($.mdc-key-cro-response) with $.mdc-key-cro-response;

            with $cro-request {
                %http-request<requestMethod> = $cro-request.method();
                %http-request<requestUrl> = $cro-request.uri.Str;
                my $user-agent = $cro-request.header('User-Agent');
                %http-request<userAgent> = $user-agent with $user-agent;
                my $referer = $cro-request.header('Referer');
                %http-request<referer> = $referer with $referer;
                %http-request<remoteIp> = $cro-request.connection.peer-host;
            }

            with $cro-response {
                # Response-size seems dangerous to obtain. Defer output until
                # after the size is available?
                # my $body = await $cro-response.body-text();
                # %http-request<responseSize> = $body.chars;
                %http-request<status>       = $cro-response.status;
            }

            $struct<httpRequest> = %http-request if %http-request.keys > 0;
        }

        if ($.use-source-location) {
            $struct<sourceLocation> = {
                filePath => $context.callframe.file,
                lineNumber => $context.callframe.line,
                functionName => $context.callframe.code.name,
            };
        }

        # Copy all MDC values to the struct except for the special CRO related entries.
        if $.use-mdc {
            for $context.mdc.kv -> $key, $value {
                next if ($key eq $.mdc-key-cro-request or $key eq $.mdc-key-cro-response);
                $struct{$key} = $value;
            }
        }

        $!handle.say(to-json($struct, :$.pretty));
    }
}

