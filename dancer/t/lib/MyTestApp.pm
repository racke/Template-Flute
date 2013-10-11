package MyTestApp;

use Dancer ':syntax';
use Dancer::Plugin::Form;

get '/' => sub {
    template 'index';
};

any [qw/get post/] => '/register' => sub {
    my $form = form('registration');
    $form->fill($form->values);
    template register => {form => $form };
};

any [qw/get post/] => '/login' => sub {
    # select the form to fill. Only one supported for now.
    my $form;
    if (params->{login}) {
        $form = form('login');
    }
    else {
        $form = form('registration');
    }
    $form->fill($form->values);
    template login => { form => $form } ;
};

any [qw/get post/] => '/bugged_single' => sub {
    template register => {};
};

any [qw/get post/] => '/bugged_multiple' => sub {
    template login => {};
};



1;

