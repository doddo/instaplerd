use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share module => 'Tuvix::InstaPlugin' => 'share';

WriteMakefile(
    NAME               => 'Tuvix::InstaPlugin',
    AUTHOR             => q{Petter H <dr.doddo@gmail.com>},
    VERSION_FROM       => 'lib/Tuvix/InstaPlugin.pm',
    ABSTRACT_FROM      => 'lib/Tuvix/InstaPlugin.pm',
    LICENSE            => 'mit',
    EXE_FILES          => [ qw{script/instaplugin_filter_demo.pl script/instaplugin_meta_edit.pl} ],
    PMLIBDIRS          => [ qw(lib inc) ],

    MIN_PERL_VERSION   => '5.008001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES     => {
        'DateTime'                => '0',
        'Image::Magick'           => '0',
        'Path::Class::File'       => '0',
        'Test::More'              => '0',
        'File::ShareDir::Install' => '0',
        'Moose'                   => '0'
    },
    PREREQ_PM          => {
        'Moose'                       => 0,
        'Carp'                        => '0',
        'DateTime::Format::Strptime'  => '0',
        'Digest::MD5'                 => '0',
        'File::ShareDir'              => '0',
        'File::Spec'                  => '0',
        'Geo::Coordinates::Transform' => '0',
        'Geo::Coder::OSM'             => '0',
        'Image::Magick'               => '0',
        'Image::ExifTool'             => '0',
        'JSON'                        => '0',
        'LWP::Protocol::https'        => '0',
        'Module::Load'                => '0',
        'Mojo::UserAgent'             => '0',
        'Mojo::Log'                   => '0',
        'Moose'                       => '0',
        'Plerd'                       => '0',
        'Pod::Usage'                  => '0',
        'Readonly'                    => '0',
        'Software::License::MIT'      => '0',
        'Text::MultiMarkdown'         => '0',
        'Text::Sprintf::Named'        => '0',
        'Try::Tiny'                   => '0',

    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean              => { FILES => 'Tuvix::InstaPlugin-*' },
);

package MY;
use File::ShareDir::Install qw(postamble);
