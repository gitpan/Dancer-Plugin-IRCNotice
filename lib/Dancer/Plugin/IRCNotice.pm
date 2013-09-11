package Dancer::Plugin::IRCNotice;

use 5.008_005;
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use IO::Socket::IP;

our $VERSION = '0.04';

register notify => sub {
  my ($message) = @_;

  info "Sending notification: $message";

  my $config = plugin_setting;

  $config->{host}    ||= 'chat.freenode.net';
  $config->{nick}    ||= sprintf('dpin%04u', int(rand() * 10000));
  $config->{name}    ||= $config->{nick};
  $config->{channel} ||= '#dpintest';

  fork and return if $config->{fork};

  # Add default port
  $config->{host} .= ':6667' unless $config->{host} =~ /:\d+$/;

  my $socket = IO::Socket::IP->new($config->{host})
    or warning "Cannot create socket: $@" and return;

  # TODO error handling srsly

  info "Registering as $config->{nick}";

  $socket->say("NICK $config->{nick}");
  $socket->say("USER $config->{nick} . . :$config->{name}");

  while (my $line = $socket->getline) {
    info "Got $line";

    if ($line =~ /End of \/MOTD/) {
      info "Sending notice to $config->{channel}";

      $socket->say("NOTICE $config->{channel} :$message");
      $socket->say("QUIT");

      info "Notice sent";
      exit if $config->{fork};
      return;
    }
  }

  info "Notice not sent";

  exit if $config->{fork};
  return;
};

register_plugin;

1;
__END__

=encoding utf-8

=head1 NAME

Dancer::Plugin::IRCNotice - Send IRC notices from your dancer app

=head1 SYNOPSIS

  use Dancer::Plugin::IRCNotice;

  notify('This is a notification');

=head1 DESCRIPTION

Dancer::Plugin::IRCNotice provides a quick and dirty way to send IRC NOTICEs to
a specific channel.

This is B<very alpha> software right now.  No error checking is done and it
uses a fork to (optionally) background the process of sending the notice.

=head1 CONFIGURATION

  plugins:
    IRCNotice:
      host: 'chat.freenode.net'
      nick: 'testnick12345'
      name: 'Dancer::Plugin::IRCNotify'
      channel: '#dpintest'
      fork: 1

The host, nick, name, and channel should be pretty obvious.  If fork is set to
a true value, the plugin will fork and background the sending of the notice.

=head1 TODO

This is so bootleg, it really needs to be cleaned up to handle IRC correctly.
Unfortunately, all of the IRC modules I saw on cpan are event based
monstrosities so this just uses L<IO::Socket::IP> to connect.

The notify routine should probably let you override the settings or maybe I
should use something like L<Dancer::Plugin::DBIC> to define multiple notifiers
that can then be used.

A connection to IRC must be made for each notification presently.  Instead, it
should try to keep a connection open and reuse it or something.  However, that
would require threads instead of simple forking, and I'm not sure how that will
play with whatever plack frontend people are using.

=head1 AUTHOR

Alan Berndt E<lt>alan@eatabrick.orgE<gt>

=head1 COPYRIGHT

Copyright 2013 Alan Berndt

=head1 LICENSE

This library is free software.  You may redistribute it under the terms of the
MIT license.

=head1 SEE ALSO

=cut
