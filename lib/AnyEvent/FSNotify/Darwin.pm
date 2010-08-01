package AnyEvent::FSNotify;

use strict;
use warnings;

use Mac::FSEvents;
use AnyEvent;

our $latency = 0.2;

sub AnyEvent::FSNotify::_run {
    my($self) = @_;
    my @watchers;
    for($self->dirs) {
        my $watcher = Mac::FSEvents->new({
            path => $_,
            latency => $latency,
        });
        push @watchers, AE::io($watcher->watch, 0, sub {
            $self->_process_event($watcher->read_events());
        });
    }
    $self->{'watcher'} = \@watchers;
}

1;
__END__
