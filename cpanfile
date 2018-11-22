requires 'perl', '5.008001';

requires 'Carp';
requires 'DateTime::Format::Strptime';
requires 'Digest::MD5';
requires 'File::ShareDir::Install'
requires 'File::Spec';
requires 'Geo::Coordinates::Transform';
requires 'Geo::Coder::OSM';
requires 'Image::Magick';
requires 'Image::ExifTool';
requires 'JSON';
requires 'Module::Load';
requires 'Moose';
requires 'Plerd';
requires 'Pod::Usage';
requires 'Readonly';
requires 'Software::License::MIT';
requires 'Text::MultiMarkdown';
requires 'Text::Sprintf::Named';
requires 'Try::Tiny';


on 'test' => sub {
    requires 'Test::More', '0.98';
};


