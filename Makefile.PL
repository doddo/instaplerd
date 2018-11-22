use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
    NAME             => 'InstaPlerd',
    AUTHOR           => q{Petter H <dr.doddo@gmail.com>},
    VERSION_FROM     => 'lib/InstaPlerd.pm',
    ABSTRACT_FROM    => 'lib/InstaPlerd.pm',
    LICENSE          => 'mit',
    EXE_FILES        => [qw{script/instaplerd_filter_demo.pl script/instaplerd_meta_edit.pl}],
    PMLIBDIRS        => [qw(lib inc)],

    MIN_PERL_VERSION => '5.008001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'DateTime'                  => '0',
        'Image::Magick'             => '0',
        'Path::Class::File'         => '0',
        'Test::More'                => '0',
        'File::ShareDir::Install'   => '0',
        'Moose'                     => '0'
    },
    PREREQ_PM => {
        'Moose'         => 0,
           'Carp'   => '0',
           'DateTime::Format::Strptime' => '0',
           'Digest::MD5'               => '0',
           'File::ShareDir::Install' => '0',
           'File::Spec'             => '0',
           'Geo::Coordinates::Transform'   => '0',
           'Geo::Coder::OSM'        => '0',
           'Image::Magick'          => '0',
           'Image::ExifTool'        => '0',
           'JSON'                   => '0',
           'Module::Load'           => '0',
           'Moose'                  => '0',
           'Plerd'                  => '0',
           'Pod::Usage'             => '0',
           'Readonly'               => '0',
           'Software::License::MIT' => '0',
           'Text::MultiMarkdown'    => '0',
           'Text::Sprintf::Named'   => '0',
           'Try::Tiny'              => '0',

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'InstaPlerd-*' },
);

package MY;
use File::ShareDir::Install qw(postamble);
