[![Docker build status](https://img.shields.io/docker/cloud/build/doddo/tuvix-insta.svg)](https://hub.docker.com/r/doddo/tuvix-insta)


# NAME

InstaPlerd - an amazing photo blog plugin for [Tuvix](https://github.com/doddo/tuvix) 

# DESCRIPTION

This adds photoblog support for  [Tuvix](https://github.com/doddo/tuvix) which is a top modern blogging platform which is based on [Plerd](https://github.com/jmacdotorg/plerd/) but renders dynamic pages with [https://github.com/mojolicious/mojo](Mojo), instead of static ones.

It uses filters which in turn use ImageMagick to "enhance" the photos, as well as performs GEO lookup, and if a "clarafai_api_key" is provided with the plugin config (see below), performs object detection through clarafai to provide tags and also maybe to set post title.
 

# How to install

First, install [Tuvix](https://github.com/doddo/tuvix), and then

curl -fsSL https://cpanmin.us | perl - --installdeps .
perl Makefile.PL
make
make test
make install

# USAGE

The idea is to use it with tuvix but it can be used in standalone mode too

## with Tuvix 

Once successfully installed, configure tuvix.conf like this.

    # example:
    extensions       => ['InstaPlerd::Post'],
    
    # Preferences for these extensions.
    # example:
    extension_preferences => {
      'InstaPlerd::Post'  => {
          width       => 847,
          height      => 840,
          compression => 85,
          filter      => 'InstaPlerd::Filters::Batman',
    }
    
If you have geo data in the pictures, you might want to also add a copyright notice:

    footer_section => '<p> All image GEO data extracted is <a href="https://www.openstreetmap.org/copyright">© OpenStreetMap contributors</a></p>'
    

finally, copy the [instaplerd_post_content.tt](share/templates/instaplerd_post_content.tt) file into the tuvix `template_path`.

And that is all there is to it. If filter is omitted, a random one will be selected. Plans exist for selecting appropriate filters based on image color leverls, and other levels of the image as well as on object detection, (for example if it is a picture of the outside then you might want to use a TiltShift filter)

 

# Docker

    docker run -p 8080:8080 doddo/tuvix-insta

and then visit http://localhost:8080



# LICENSE

Copyright (C) Petter H

This library is released under the MIT license. The Flag icons are from  [www.famfamfam.com](http://www.famfamfam.com/lab/icons/flags/).
If enabled, The GEO lookup data resolved from the jpeg EXIF any processed images is [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright).

The [Instagraph](lib/Tuvix/InstaPlugin/Filters/InstaGraph) filters have been copied from the [InstaGraph](https://github.com/adineer/instagraph) project, 
and translated to Filters for this project. Similarly, the corresponding borders  borders  for the Kelvin and  They are released under the MIT Licence.

# AUTHOR

Petter H <dr.doddo@gmail.com>
