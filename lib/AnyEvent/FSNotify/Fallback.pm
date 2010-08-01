package AnyEvent::FSNotify::Fallback;

use strict;
use warnings;

use AnyEvent;

sub AnyEvent::FSNotify::_run {
    my($self) = @_;
    $self->{watcher} = AE::timer 2.0, 0, sub {
        $self->_process_events;
        $self->_run;
    };
}

1;
