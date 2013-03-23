package MyTestApp;

use Dancer ':syntax';

get '/' => sub {
    set template => 'template_flute';
    set views => 't/views';

    template 'index';
};

1;

