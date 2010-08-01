package AnyEvent::FSNotify::Linux;

use strict;
use warnings;

use Linux::Inotify2;
use AnyEvent;
use Carp qw();

our $latency = 0.2;

sub AnyEvent::FSNotify::_run {
    my($self) = @_;

    my $inotify = Linux::Inotify2->new()
        or Carp::croak "Unable to create new Linux::Inotify2 object";

    my $watch; $watch = sub {
        File::Find::find(sub {
            return if not -d $File::Find::name;
            $inotify->watch(
                $File::Find::name,
                IN_MODIFY | IN_CREATE | IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF,
                sub {
                    my($e) = @_;
                    if($e->IN_CREATE && $e->IN_ISDIR) {
                        $watch->($e->fullname) 
                    }

                    # Latency like Mac::FSEvents
                    $self->{'_sync_timer'} ||= AE::timer $latency, 0, sub {
                        undef $self->{'_sync_timer'};
                        $self->_process_event($e);
                    };
                }
            );
        }, @_);
    };

    $watch->($self->dirs);

    $self->{'watcher'} = AE::io $inotify->fileno, 0, sub {
        $inotify->poll;
    };
}

1;
__END__
