use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Flute::PDF',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Template/Flute/PDF.pm',
    ABSTRACT_FROM       => 'lib/Template/Flute/PDF.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Template::Flute' => 0,
        'Template::Flute::Style::CSS' => 0.0002,
		'PDF::API2' => 0,
        'Image::Size' => 0,
        'Image::Magick' => 0,
	},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Flute-PDF-*' },
);
