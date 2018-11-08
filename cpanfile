requires 'perl', '5.008001';

requires 'Carp';
requires 'DateTime::Format::Strptime';
requires 'Geo::Coordinates::Transform';
requires 'Geo::Coder::OSM';
requires 'File::Spec';
requires 'Image::Magick';
requires 'Moose';
requires 'Readonly';
requires 'Try::Tiny';

on 'test' => sub {
    requires 'Test::More', '0.98';
};


