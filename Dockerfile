FROM node:10

RUN apt-get update \
 && apt-get install -y checkinstall \
 && apt-get clean \
 && find /var/lib/apt/lists/ /tmp/ /var/tmp/ -mindepth 1 -maxdepth 1 -exec rm -rf "{}" +

# Build QPDF
RUN cd /tmp \
 && wget https://s3.amazonaws.com/sharelatex-random-files/qpdf-6.0.0.tar.gz \
 && tar xzf qpdf-6.0.0.tar.gz \
 && cd qpdf-6.0.0 \
 && ./configure \
 && make \
 && checkinstall -Dy --pkgname qpdf --pkgversion 6.0.0 \
 && mv qpdf_6.0.0-1_amd64.deb /qpdf.deb \
 && cd / \ 
 && find /tmp/ -mindepth 1 -maxdepth 1 -exec rm -rf "{}" +

# Install clsi
RUN git clone https://github.com/sharelatex/clsi-sharelatex /app \
 && cd /app \
 && git checkout a62ff6e248d624c5ad78dbf08bb4613b043abdc2 \
 && npm install \
 && npm run compile:all \
 && rm -rf .git \
 && mkdir -p data/cache data/compiles \
 && touch data/db.sqlite \
 && chown -R node:node .



FROM node:10-slim

COPY --from=0 /qpdf.deb /qpdf.deb
RUN dpkg -i /qpdf.deb \
 && rm /qpdf.deb

# Copy clsi
COPY --chown=node:node --from=0 /app /app

# Add config
ADD --chown=node:node ./settings.clsi.coffee /app/config/settings.clsi.coffee
ENV SHARELATEX_CONFIG /app/config/settings.clsi.coffee

# Link synctex
RUN ln -s /app/bin/synctex /opt/synctex

# Install TeX Live
RUN apt-get update \
 && apt-get install -y perl ghostscript \
 && apt-get clean \
 && find /var/lib/apt/lists/ /tmp/ /var/tmp/ -mindepth 1 -maxdepth 1 -exec rm -rf "{}" + \
 \
 && wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
 && mkdir /install-tl-unx \
 && tar -xvf install-tl-unx.tar.gz -C /install-tl-unx --strip-components=1 \
 && echo "selected_scheme scheme-full" >> /install-tl-unx/texlive.profile \
 && /install-tl-unx/install-tl -profile /install-tl-unx/texlive.profile \
 && rm -r /install-tl-unx \
 && rm install-tl-unx.tar.gz

ENV PATH "/usr/local/texlive/2019/bin/x86_64-linux/:${PATH}"

RUN tlmgr install latexmk texcount

WORKDIR /app
USER node
EXPOSE 3013
VOLUME /app/data
ENTRYPOINT ["node", "app.js"]
