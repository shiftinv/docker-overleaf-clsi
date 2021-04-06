# Intermediate step for ensuring correct permissions on binaries
FROM node:10-buster-slim AS texlive-bin-extract
ADD ./texlive-bin-x86_64-linux.tar.gz /texlive-bin
RUN chown -R 0:0 /texlive-bin \
 && chmod -R 755 /texlive-bin



FROM node:10-buster

RUN apt-get update \
 && apt-get install -y qpdf perl ghostscript curl wget gnupg \
 && apt-get clean \
 && find /var/lib/apt/lists/ /tmp/ /var/tmp/ -mindepth 1 -maxdepth 1 -exec rm -rf "{}" +

# Install tini
RUN curl -sSL https://github.com/krallin/tini/releases/download/v0.19.0/tini -o /tini \
 && chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# Install clsi
RUN git clone https://github.com/shiftinv/overleaf-clsi /app \
 && cd /app \
 && git checkout dev \
 && rm -rf .git \
 && npm install \
 && chown -R node:node . \
 && find /root/.cache /root/.npm /tmp /var/tmp -mindepth 1 -maxdepth 1 -exec rm -rf "{}" +

# Create data directories
RUN cd /app \
 && mkdir -p data/cache data/compiles \
 && touch data/db.sqlite \
 && chown -R node:node data


# Install TeX Live

# prefix with underscores to avoid collisions with TeXLive
ARG _TEXLIVE_MIRROR=http://mirror.ctan.org/systems/texlive/tlnet
# scheme options: scheme-basic, scheme-small, scheme-medium, scheme-full
ARG _TEXLIVE_SCHEME=scheme-basic

ENV _TEXLIVE_PATH "/usr/local/texlive/2021"
ENV PATH "${PATH}:${_TEXLIVE_PATH}/bin/x86_64-linux"

ARG _TEXLIVE_CACHEBUSTER=

RUN mkdir /install-tl-unx \
 && curl -sSL ${_TEXLIVE_MIRROR}/install-tl-unx.tar.gz \
    | tar -xzC /install-tl-unx --strip-components=1 \
  \
 && echo "tlpdbopt_autobackup 0" >> /install-tl-unx/texlive.profile \
 && echo "tlpdbopt_install_docfiles 0" >> /install-tl-unx/texlive.profile \
 && echo "tlpdbopt_install_srcfiles 0" >> /install-tl-unx/texlive.profile \
 && echo "selected_scheme ${_TEXLIVE_SCHEME}" >> /install-tl-unx/texlive.profile \
  \
 && /install-tl-unx/install-tl \
      -profile /install-tl-unx/texlive.profile \
      -repository ${_TEXLIVE_MIRROR} \
  \
 && rm -rf /install-tl-unx \
 && rm -rf "${_TEXLIVE_PATH}/bin/x86_64-linux"

# make sure that year in _TEXLIVE_PATH is correct
RUN test -d "${_TEXLIVE_PATH}"

# replace binaries
COPY --from=texlive-bin-extract /texlive-bin/x86_64-linux "${_TEXLIVE_PATH}/bin/x86_64-linux"
# make sure extraction worked
RUN test -f "${_TEXLIVE_PATH}/bin/x86_64-linux/tex"

RUN tlmgr option repository ${_TEXLIVE_MIRROR}
RUN tlmgr install latexmk texcount


# don't read any other .latexmkrc files
ENV LATEXMKRCSYS "/opt/latexmkrc"
RUN echo "\$auto_rc_use = 0;" > "${LATEXMKRCSYS}"

# set openout/openin to paranoid
RUN echo "openout_any = p\nopenin_any = p" >> "${_TEXLIVE_PATH}/texmf.cnf"

# Add config
COPY --chown=node:node ./settings.clsi.coffee /app/config/settings.clsi.coffee
ENV SHARELATEX_CONFIG /app/config/settings.clsi.coffee

# Link synctex
RUN ln -s /app/bin/synctex /opt/synctex

WORKDIR /app
USER node
EXPOSE 3013
VOLUME /app/data
CMD ["node", "app.js"]
