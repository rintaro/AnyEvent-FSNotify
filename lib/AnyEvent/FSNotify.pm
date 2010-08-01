package AnyEvent::FSNotify;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw();
use File::Find qw();

sub _run;
BEGIN {
    (
        $^O eq 'linux'  ? require AnyEvent::FSNotify::Linux :
        $^O eq 'darwin' ? require AnyEvent::FSNotify::Darwin : 0
    )
    or require AnyEvent::FSNotify::Fallback;
}

sub new {
    my($class, %conf) = @_;

    my $dirs = $conf{dirs};
    my $cb = $conf{cb};

    if(not($dirs and $cb) or ref $cb ne 'CODE') {
        Carp::croak 'Usage: AnyEvent::FSNotify->new($path1, $path2, ... , sub { })';
    }

    if(not ref($dirs) or ref($dirs) ne 'ARRAY') {
        $dirs = [$dirs];
    }

    my $self = bless {
        dirs => [@$dirs],
        cb => $cb,
    }, $class;

    $self->{'_fs'} = $self->_fs_scan;
    $self->_run;

    $self;
}

sub dirs {
    @{shift->{'dirs'}};
}

sub _process_event {
    my($self, @raw_events) = @_;
    # We don't care about events from driver, but scan filesystem.

    my $new_fs = $self->_fs_scan;
    my $events = _compare_fs($self->{'_fs'}, $new_fs);
    $self->{'_fs'} = $new_fs;

    $self->{'cb'}->(@$events) if @$events;
}

sub _fs_scan {
    my($self) = @_;
    my %entries;
    for my $dir ($self->dirs) {
        File::Find::find(sub {
            my @stat = stat $File::Find::name;
            $entries{$File::Find::name} = [
                -d _,     # is_dir
                $stat[9], # mtime
                $stat[7], # size
            ];
        }, $dir);
    }
    \%entries;
}

sub _compare_fs {
    my($old, $new) = @_;

    my @events =
        map +{type => 'created', path => $_},
        grep {! exists $old->{$_}} keys %$new;

    for (keys %$old) {
        if(not exists $new->{$_}) {
            push @events, {type => 'deleted', path => $_};
        }
        elsif(
            ! $new->{$_}[0] # is_dir
            and
               $old->{$_}[1] != $new->{$_}[1] # mtime
            || $old->{$_}[2] != $new->{$_}[2] # size
        ) {
            push @events, {type => 'modified', path => $_}
        }
    }

    \@events;
}

1;
__END__

=head1 NAME

AnyEvent::FSNotify - AnyEvent compatible module to monitor filesystem for changes 

=head1 SYNOPSIS

  use AnyEvent::FSNotify;
  
  my $watcher = AnyEvent::FSNotify->new(dirs => [$dir1, $dir2, ...], cb => sub {
      my @events = @_;
      for my $event (@events) {
      print "$event->{type} : $event->{path}\n";
  });
  
  $cv->recv;

=head1 DESCRIPTION

This module is yet another L<AnyEvent::Filesys::Notify>, without Moose.

=head1 METHODS

=head2 new($dir1, $dir2, .., sub { ... })

Initializes monitor.

=head1 AUTHOR

Rintaro Ishizaki E<lt>rintaro@cpan.orgE<gt>

=head1 SEE ALSO

Depends L<Linux::INotify2>, L<Mac::FSEvents> and L<AnyEvent>.

Alternatives L<AnyEvent::Filesys::Notify>, L<Filesys::Notify::Simple>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
