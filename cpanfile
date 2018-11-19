requires 'perl', '5.008001';

requires 'Carp';
requires 'Plerd';
requires 'DateTime::Format::Strptime';
requires 'Geo::Coordinates::Transform';
requires 'Geo::Coder::OSM';
requires 'File::Spec';
requires 'Image::Magick';
requires 'Image::ExifTool';
requires 'Moose';
requires 'Readonly';
requires 'Try::Tiny';
requires 'Software::License::MIT';
requires 'Text::Sprintf::Named';
requires 'Digest::MD5';
requires 'JSON';

on 'test' => sub {
    requires 'Test::More', '0.98';
};


