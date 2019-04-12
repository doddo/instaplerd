FROM doddo/tuvix

USER root
RUN apt update && apt install libperl-dev

WORKDIR /opt/
RUN wget http://www.imagemagick.org/download/ImageMagick-7.0.8-39.tar.xz 
RUN tar xvf ImageMagick-7.0.8-39.tar.xz
RUN (cd ImageMagick-7.0.8-39 &&  ./configure --with-modules=yes --enable-shared=yes --with-quantum-depth=16 --with-perl && make && make install)


RUN ldconfig

WORKDIR /opt/ImageMagick-7.0.8-39/PerlMagick
RUN perl Makefile.PL
RUN make 
RUN make test
RUN make install


USER tuvix
COPY --chown=tuvix . /tmp/instaplerd
WORKDIR /tmp/instaplerd 

RUN cpanm  -M https://cpan.metacpan.org  --notest --installdeps .
RUN cpanm install .

