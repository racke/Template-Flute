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

any [qw/get post/] => '/login' => sub {
    my %params = params;
    # debug(to_dumper(request));
    debug(to_dumper(\%params));
    my $register = form('registration');
    my $login = form('login');
    debug to_dumper($login->values);
    debug to_dumper($register->values);
    # my $values = $form->values;
    # debug to_dumper($values);
    # $form->fill($values);
    template login => { form => $register } ;
};




1;

