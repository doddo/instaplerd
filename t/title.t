use strict;
use warnings;
use Test::More 0.98;

use strict;
use warnings FATAL => 'all';

use File::Copy;
use Path::Class::File;

use FindBin;

use lib "$FindBin::Bin/../lib";


use InstaPlerd::Post;
use Plerd;

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
    extensions       => [ 'InstaPlerd' ],
    base_uri         => URI->new('http://blog.example.com/'),
    image            => URI->new('http://blog.example.com/logo.png'),
);

my $img_file = Path::Class::File->new($img_file_name);

ok(my $post = InstaPlerd::Post->new(source_file => $img_file, plerd => $plerd));

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


done_testing;

1;