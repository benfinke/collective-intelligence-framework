#!/usr/bin/perl -w

use strict;

use CIF::Message::URLPhishing;
use Data::Dumper;
use Text::Table;

my $hash;
my @recs = CIF::Message::URLPhishing->retrieve_from_sql('detecttime >= \'2010-06-01 00:00:00Z\'');

foreach my $rec (@recs){
    my $key = $rec->url_sha1();
    next if(exists($hash->{$key}));
    $hash->{$key} = $rec;
}

my $t = Text::Table->new(
    { title => '# address', align => 'left' }, { is_sep => 1, title => ' | ' }, 
    "description", { is_sep => 1, title => ' | ' },
    "url_sha1", { is_sep => 1, title => ' | ' },
    "url_md5", { is_sep => 1, title => ' | ' }, 
    'confidence', { is_sep => 1, title => ' | ' },
    'severity', { is_sep => 1, title => ' | ' },
    'restriction', { is_sep => 1, title => ' | ' },
    'uuid',
);

my @sort = sort { $hash->{$a}->{'confidence'} <=> $hash->{$b}->{'confidence'} } keys %$hash;

foreach my $h (@sort){
    my $r = $hash->{$h};
    $t->load([ 
        $r->address(),
        $r->description(),
        $r->url_sha1(),
        $r->url_md5(),
        $r->confidence(),
        $r->severity(),
        $r->restriction(),
        $r->uuid(),
    ]);
}

warn $t;