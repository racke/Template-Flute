# Testing basic methods of form object
use strict;
use warnings;
use Test::More;

use Template::Flute;

my $sort_form_spec = <<EOF;
<form name="sort" link="name">
<field name="sort"/>
</form>
EOF

my $sort_form_template = <<EOF;
    Razvrsti po:
<select name="sort" class="sort" onChange="this.form.submit()">
    <option value="priority">Priljubljenosti</option>
    <option value="price">Cena</option>
</select>
</form>
EOF

my @form_att_tests = ({html => q{<form name="sort" action="/search">},
                       method => 'GET',
                       action => '/search',
                   },
                      {html => q{<form name="sort" method="get">},
                       method => 'GET',
                       action => '',
                   },
                      {html => q{<form name="sort" action="test" method="pOSt">},
                       method => 'POST',
                       action => 'test',
                   },
                  );

plan tests => 8 * scalar(@form_att_tests);

for my $test (@form_att_tests) {
    my $flute = Template::Flute->new(specification => $sort_form_spec,
                                     template => $test->{html} . $sort_form_template,
                                 );

    $flute->process_template;

    my $form = $flute->template->form('sort');

    isa_ok($form, 'Template::Flute::Form');
    ok(scalar(@{$form->elts} == 1), "Checking number of form elements.");

    my $action = $form->action;

    ok(defined $action && $action eq $test->{action}, 'Return value of action method')
        || diag "$action instead of $test->{action}";

    my $method = $form->method;

    ok(defined $method && $method eq $test->{method}, 'Return value of method method')
        || diag "$method instead of $test->{method}";

    $form->set_action('/action');

    $action = $form->action;

    ok(defined $action && $action eq '/action',
       'Return value of action method after setting to /action')
        || diag "$action instead of /action";

    my $attval = $form->elt->att('action');

    ok(defined $attval && $attval eq '/action',
       'Value of element action attribute after setting to /action')
        || diag "$attval instead of /action";

    $form->set_method('POST');

    $method = $form->method;

    ok(defined $method && $method eq 'POST',
       'Return value of method method after setting to POST')
        || diag "$method instead of POST";

    $attval = $form->elt->att('method');

    ok(defined $attval && $attval eq 'POST',
       'Value of element method attribute after setting to POST')
        || diag "$attval instead of POST";
}
