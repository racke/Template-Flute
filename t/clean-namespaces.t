use strict;
use warnings;
use Test::More;
use Test::CleanNamespaces;

# eventually this should simply call 'all_namespace_clean' but for now we
# just add things we expect to be clean...
#

#all_namespace_clean;

namespaces_clean('Template::Flute::Iterator');

done_testing;
