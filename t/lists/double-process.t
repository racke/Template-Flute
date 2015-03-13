use Template::Flute;

my $spec = q{<specification>
<list name="list" iterator="test">
<param name="value"/>
</list>
</specification>
};

my $html = q{<html><div class="list"><div class="value">TEST</div></div></html>};

$flute = Template::Flute->new(
    template      => $html,
    specification => $spec,
    values        => { test => [ { value => $value } ] },
);

$flute->process;
$flute->process;

exit;
