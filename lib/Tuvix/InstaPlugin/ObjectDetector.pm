package Tuvix::InstaPlugin::ObjectDetector;
use strict;
use warnings FATAL => 'all';

use MIME::Base64 qw/encode_base64/;
use Moose;
use Mojo::UserAgent;
use Mojo::Log;

# TODO fix this
my $API_URL = "https://api.clarifai.com/v2/models/aaa03c23b3724a16a56b629203edc62c/versions/aa7f35c01e0642fda5cf400f543e7c40/outputs";

has 'clarafai_api_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has log => (
    is      => 'ro',
    isa     => 'Mojo::Log',
    default => sub {Mojo::Log->new()}
);

has image => (
    is       => 'ro',
    isa      => 'Image::Magick',
    required => 1
);

has concepts => (
    is  => 'rw',
    isa => 'HashRef[Str]',
);

has response => (
    is  => 'rw',
    isa => 'Maybe[Mojo::Message::Response]',
);

sub process {
    my $self = shift;
    my $concepts;
    my $ua = Mojo::UserAgent->new();
    my $res = $ua->post(
        $API_URL =>
            {
                "Authorization" => "Key " . $self->clarafai_api_key,
                "Content-Type"  => "application/json"
            }    => json => {
            inputs => [
                {
                    data => {
                        image => {
                            base64 => encode_base64($self->image->ImageToBlob())
                        }
                    }
                }
            ]
        })->result;

    $self->response($res);

    if ($res->is_success && $res->json // 0) {
        if (uc(${$res->json}{status}{description}) eq 'OK') {
            foreach my $result (@{${$res->json}{outputs}}) {
                $self->log->info(sprintf "Status:%s Code:%s",
                    $$result{status}{description} // 'unknon', $$result{status}{code} // 'unknown');

                foreach my $concept (@{$$result{data}{concepts}}) {
                    $$concepts{$$concept{name}} = $$concept{value};
                }
            }
            $self->concepts($concepts);
        }
        else {
            $self->log->error("Unable to perform object detection: Status not OK, but instead: " .
                ${$res->json}{status}{description});
        }
    }
    else {
        $self->log->error("Unable to perform object detection: " .
            $res->is_error ? $res->message : 'Unknown error')
    }
}


1;