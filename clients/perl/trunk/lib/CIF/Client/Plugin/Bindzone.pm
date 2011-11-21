package CIF::Client::Plugin::Bindzone;

sub type { return 'output'; }

sub write_out {
    my $self = shift;
    my $config = shift;
    my $feed = shift;
    my @array = @{$feed->{'feed'}->{'entry'}};

    my $text = '; generated by: '.$0." at ".time()."\n";
    foreach (@array){
        $text .= 'zone "'.$_->{'address'}.'" {type master; file "/etc/namedb/cif_blockeddomain.hosts";};'."\n";
    }
    return $text;
}
1;