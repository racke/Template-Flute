package MyTestApp;

use Dancer ':syntax';
use Dancer::Plugin::Form;

get '/' => sub {
    template 'index';
};

any [qw/get post/] => '/register' => sub {
    my $form = form('registration');
    my %values = %{$form->values};
    # VALIDATE, filter, etc. the values
    $form->fill(\%values);
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

any [qw/get post/] => '/multiple' => sub {
    my $login = form('logintest');
    debug to_dumper({params});
    if (params->{login}) {
        my %vals = %{$login->values};
        # VALIDATE %vals here
        $login->fill(\%vals);
    }
    else {
        # pick from session
        $login->fill;
    }
    my $registration = form('registrationtest');
    if (params->{register}) {
        my %vals = %{$registration->values};
        # VALIDATE %vals here
        $registration->fill(\%vals);
    }
    else {
        # pick from session
        $registration->fill;
    }
    template multiple => { form => [ $login, $registration ] };
};

any [qw/post get/] => '/checkout' => sub {
    my (@days, @years);
    for (1..31) {
        push @days, { value => $_, label => "Day $_" };
    }
    for (2012..2020) {
        push @years, { value => $_, label => "Year $_" };
    }
    my $form = form('giftinfo');
    if (params->{submit}) {
        my %values = %{$form->values};
        $form->fill(\%values);
    }
    else {
        $form->fill;
    }

    my $detform = form('giftdetails');
    if (params->{submit_details}) {
        my %values = %{$detform->values};
        $detform->fill(\%values);
    }
    else {
        $detform->fill;
    }

    template 'checkout-giftinfo' => {
                                     form => [ $form, $detform ],
                                     days => \@days,
                                     years => \@years
                                    };
};

1;

