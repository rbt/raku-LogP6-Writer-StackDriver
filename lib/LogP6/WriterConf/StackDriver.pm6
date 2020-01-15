use LogP6::WriterConf::Pattern;
use LogP6::WriterConf;
use LogP6::Level;
use LogP6::Writer::StackDriver;

class LogP6::WriterConf::StackDriver does LogP6::WriterConf {
	has Str $.name;
	has Bool $.use-mdc = True;
	has Bool $.use-mdc-cro = True;
	has Str $.mdc-key-cro-request = 'cro-request';
	has Str $.mdc-key-cro-response = 'cro-response';
	has IO::Handle $.handle;
    has Bool $.use-source-location = True;

	method name(--> Str) {
		$!name;
	}

	method clone-with-name($name --> LogP6::WriterConf:D) {
		self.clone(:$name);
	}

	method self-check(--> Nil) { }

	method make-writer(*%defaults --> LogP6::Writer:D) {
		my $handle = $!handle // %defaults<default-handle>;

		LogP6::Writer::StackDriver.new(:$handle, :$.use-mdc, :$.use-mdc-cro, :$.mdc-key-cro-request, :$.mdc-key-cro-response, :$.use-source-location );
	}

	method close() {
		with $!handle {
			$!handle.close unless $!handle eqv $*OUT || $!handle eqv $*ERR
		}
	}
}