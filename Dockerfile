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
RUN git clone https://github.com/shiftinv/overleaf-clsi /app \
 && cd /app \
 && git checkout dev \
 && rm -rf .git \
 && npm install \
 && npm run compile:all \
 && chown -R node:node . \
 && find /root/.cache /root/.npm /tmp /var/tmp -mindepth 1 -maxdepth 1 -exec rm -rf "{}" +

# Create data directories
RUN cd /app \
 && mkdir -p data/cache data/compiles \
 && touch data/db.sqlite



FROM node:10-buster-slim

# Install TeX Live
RUN apt-get update \
 && apt-get install -y perl ghostscript curl wget \
 && apt-get clean \
 && find /var/lib/apt/lists/ /tmp/ /var/tmp/ -mindepth 1 -maxdepth 1 -exec rm -rf "{}" +

ARG TEXLIVE_MIRROR=http://mirror.ctan.org/systems/texlive/tlnet
# scheme options: scheme-basic, scheme-small, scheme-medium, scheme-full
ARG TEXLIVE_SCHEME=scheme-basic

ENV PATH "${PATH}:/usr/local/texlive/2020/bin/x86_64-linux"

RUN mkdir /install-tl-unx \
 && curl -sSL ${TEXLIVE_MIRROR}/install-tl-unx.tar.gz \
    | tar -xzC /install-tl-unx --strip-components=1 \
  \
 && echo "tlpdbopt_autobackup 0" >> /install-tl-unx/texlive.profile \
 && echo "tlpdbopt_install_docfiles 0" >> /install-tl-unx/texlive.profile \
 && echo "tlpdbopt_install_srcfiles 0" >> /install-tl-unx/texlive.profile \
 && echo "selected_scheme ${TEXLIVE_SCHEME}" >> /install-tl-unx/texlive.profile \
  \
 && /install-tl-unx/install-tl \
      -profile /install-tl-unx/texlive.profile \
      -repository ${TEXLIVE_MIRROR} \
  \
 && rm -rf /install-tl-unx

RUN tlmgr option repository ${TEXLIVE_MIRROR}
RUN tlmgr install latexmk texcount

# Install qpdf
COPY --from=0 /qpdf.deb /qpdf.deb
RUN dpkg -i /qpdf.deb \
 && rm /qpdf.deb

# Copy clsi
COPY --chown=node:node --from=0 /app /app

# Add config
COPY --chown=node:node ./settings.clsi.coffee /app/config/settings.clsi.coffee
ENV SHARELATEX_CONFIG /app/config/settings.clsi.coffee

# Link synctex
RUN ln -s /app/bin/synctex /opt/synctex

WORKDIR /app
USER node
EXPOSE 3013
VOLUME /app/data
ENTRYPOINT ["node", "app.js"]
