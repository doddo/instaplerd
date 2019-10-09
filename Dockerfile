FROM doddo/tuvix

USER root
RUN apt update && apt install libperl-dev

WORKDIR /opt/
ADD https://imagemagick.org/download/releases/ImageMagick-7.0.8-68.tar.xz /opt
RUN tar xf ImageMagick-7.0.8-68.tar.xz
WORKDIR /opt/ImageMagick-7.0.8-68
RUN ./configure --with-modules=yes --enable-shared=yes --with-quantum-depth=16 --with-perl 
RUN make
RUN make install

RUN ldconfig

WORKDIR /opt/ImageMagick-7.0.8-68/PerlMagick
RUN perl Makefile.PL
RUN make 
RUN make test
RUN make install


USER tuvix
COPY --chown=tuvix . /tmp/instaplerd
WORKDIR /tmp/instaplerd 

RUN cpanm  -M https://cpan.metacpan.org  --notest --installdeps .
RUN cpanm -v install .

WORKDIR /opt/tuvix 
