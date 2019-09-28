use strict;
use warnings;
use Test::More 0.98;

use strict;
use warnings FATAL => 'all';

use File::Copy;
use Path::Class::File;

use FindBin;

use lib "$FindBin::Bin/../lib";


use Tuvix::InstaPlugin::Post;
use Plerd;


my @bad_file_names = (
    'Foto 25.09.19, 19 09 42.jpg',
    'received_2348428021892972.jpeg',
    '2019-01-06-img-20190106-214653-64x64.jpeg'
);


my $img_file_name = "$FindBin::Bin/source/slask/IMG_20190106_214653_64x64.jpg";

unlink $img_file_name if (-f $img_file_name);

copy("$FindBin::Bin/source/IMG_20190106_214653_64x64.jpg", $img_file_name)
    or die "Cannot setup test file $img_file_name: $!\n";

my $plerd = Plerd->new(
    path             => "$FindBin::Bin/target",
    publication_path => "$FindBin::Bin/target/public",
    title            => 'Test Blog',
    author_name      => 'Nobody',
    author_email     => 'nobody@example.com',
    extensions       => [ 'Tuvix::InstaPlugin' ],
    base_uri         => URI->new('http://blog.example.com/'),
    image            => URI->new('http://blog.example.com/logo.png'),
);

my $img_file = Path::Class::File->new($img_file_name);

ok(my $post = Tuvix::InstaPlugin::Post->new(source_file => $img_file, plerd => $plerd));

unlike($post->title,
    qr/Summer/i,
    'Dont put summer in the title if the picture is taken during the winter'
);
for (my $i = 0; $i < 100; $i++) {
    my $title = $post->title_generator->generate_title($img_file->basename);
    unlike($title,
        qr/Summer/i,
        "'$title' does not contain summer, because it's taken in winter."
    );
}

foreach my $bad_file_name (@bad_file_names){
    my $title = $post->title_generator->generate_title($bad_file_name);
    cmp_ok ($title, 'ne', $post->title_generator->_capitalise($bad_file_name),
        "$title is NOT used to create post title '$bad_file_name'" );
}

done_testing;

1;
