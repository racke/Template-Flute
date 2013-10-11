package MyTestApp;

use Dancer ':syntax';
use Dancer::Plugin::Form;

get '/' => sub {
    template 'index';
};

any [qw/get post/] => '/register' => sub {
    my $form = form('registration');
    my $values = $form->values;
    # debug to_dumper($values);
    $form->fill($values);
    template 'register', {form => $form };
};

1;

