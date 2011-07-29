package CIF::Archive::DataType::Plugin::Countrycode;
use base 'CIF::Archive::DataType';

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.00_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

use Module::Pluggable require => 1, search_path => [__PACKAGE__];

__PACKAGE__->table('countrycode');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw/id uuid cc source severity confidence restriction detecttime created/);
__PACKAGE__->columns(Essential => qw/id uuid cc source severity confidence restriction detecttime created/);
__PACKAGE__->sequence('countrycode_id_seq');

__PACKAGE__->set_sql('feed' => qq{
    SELECT count(cc),cc,max(detecttime) as detecttime
    FROM __TABLE__
    WHERE detecttime >= ?
    AND confidence >= ?
    AND severity >= ?
    AND restriction <= ?
    GROUP BY cc
    ORDER BY count DESC
    LIMIT ?
});

sub prepare {
    my $class = shift;
    my $info = shift;

    ## TODO -- download list of IANA country codes for use in regex
    ## http://data.iana.org/TLD/tlds-alpha-by-domain.txt
    return unless($info->{'cc'});
    return unless($info->{'cc'} =~ /^[a-zA-Z]{2,2}$/);
    return(1);
}

sub insert {
    my $class = shift;
    my $info = shift;

    return unless($info->{'cc'});

    # you could create different buckets for different country codes
    my $tbl = $class->table();
    foreach($class->plugins()){
        if(my $t = $_->prepare($info)){
            $class->table($t);
        }
    }

    my $id = eval { $class->SUPER::insert({
        uuid        => $info->{'uuid'},
        cc          => $info->{'cc'},
        source      => $info->{'source'},
        severity    => $info->{'severity'} || 'null',
        confidence  => $info->{'confidence'},
        restriction => $info->{'restriction'} || 'private',
        detecttime  => $info->{'detecttime'},
    }) };
    if($@){
        return(undef,$@) unless($@ =~ /duplicate key value violates unique constraint/);
        $id = CIF::Archive->retrieve(uuid => $info->{'uuid'});
    }
    $class->table($tbl);
    return($id);
}

sub feed {
    my $class = shift;
    my $info = shift;
    my @feeds;

    ## TODO -- same as rir ans asn
    return(\@feeds);
    $info->{'key'} = 'cc';
    my $ret = $class->SUPER::feed($info);
    push(@feeds,$ret) if($ret);

    foreach($class->plugins()){
        my $t = $_->set_table();
        my $r = $_->SUPER::feed($info);
        push(@feeds,$r) if($r);
    }
    return(\@feeds);
}

sub lookup {
    my $class = shift;
    my $info = shift;
    my $query = ($info->{'query'});
    return unless($query =~ /^[a-z]{2,2}$/);

    my @args = ($query,$info->{'severity'},$info->{'confidence'},$info->{'restriction'},$info->{'limit'});
    return $class->SUPER::lookup(@args);
}

__PACKAGE__->set_sql('lookup' => qq{
    SELECT __ESSENTIAL__
    FROM __TABLE__
    WHERE upper(cc) = upper(?)
    AND severity >= ?
    AND confidence >= ?
    AND restriction <= ?
    ORDER BY detecttime DESC, created DESC, id DESC
    LIMIT ?
});

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CIF::Archive::DataType::Plugin::Countrycode - CIF::Archive plugin for indexing country codes

=head1 SEE ALSO

 http://code.google.com/p/collective-intelligence-framework/
 CIF::Archive

=head1 AUTHOR

 Wes Young, E<lt>wes@barely3am.comE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2011 by Wes Young (claimid.com/wesyoung)
 Copyright (C) 2011 by the Trustee's of Indiana University (www.iu.edu)
 Copyright (C) 2011 by the REN-ISAC (www.ren-isac.net)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
