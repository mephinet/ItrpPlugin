package Foswiki::Plugins::ItrpPlugin;

use strict;
use warnings;

use Foswiki::Func    ();    # The plugins API
use Foswiki::Plugins ();    # For the API version
use JSON             ();

# Note:  Alpha versions compare as numerically lower than the non-alpha version
# so the versions in ascending order are:
#   v1.2.1_001 -> v1.2.1 -> v1.2.2_001 -> v1.2.2

use version; our $VERSION = version->declare("v1.0.0");

our $RELEASE           = "$VERSION";
our $SHORTDESCRIPTION  = 'Integrate ITRP into Foswiki';
our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.3 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    Foswiki::Func::registerTagHandler( 'ITRPTEAMCOORDINATOR',
        \&_ITRPTEAMCOORDINATOR );

    Foswiki::Func::registerRESTHandler(
        'teamCoordinator', \&rest_team_coordinator,
        authenticate => 1,  # Set to 0 if handler should be useable by WikiGuest
        validate     => 1,  # Set to 0 to disable StrikeOne CSRF protection
        http_allow => 'POST', # Set to 'GET,POST' to allow use HTTP GET and POST
        description => 'Get team\'s coordinator'
    );

    # Plugin correctly initialized
    return 1;
}

sub _format_error_msg {
    my $s = shift;
    return "<font color=\"red\">ItrpPlugin: $s</font>";
}

sub _ITRPTEAMCOORDINATOR {
    my ( $session, $params, $topic, $web, $topicObject ) = @_;

    my $team_id = $params->{team}
      or return _format_error_msg('parameter team missing');
    $team_id =~ /^[0-9]+$/
      or return _format_error_msg('parameter team invalid');
    my $server = $Foswiki::cfg{Plugins}{ItrpPlugin}{URL}
      or return _format_error_msg('Plugin parameter URL not configured');
    my $token = $Foswiki::cfg{Plugins}{ItrpPlugin}{API_Token}
      or return _format_error_msg('Plugin parameter API_Token not configured');

    my $url =
      URI->new( $server . '/v1/teams/' . $team_id . '?api_token=' . $token,
        'http' );

    my $resource = Foswiki::Func::getExternalResource($url);

    if ( !$resource->is_error() && $resource->isa('HTTP::Response') ) {
        my $content = $resource->decoded_content();
        my $res     = JSON::from_json($content);
        return $res->{coordinator}->{name} || '-';
    }
    else {
        my $error = $resource->message() || 'unknown error';
        return _format_error_msg(
            "Failed to get team coordinator from ITRP server: $error");
    }
}

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2014 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
