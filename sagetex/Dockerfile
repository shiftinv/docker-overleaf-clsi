ARG BASE_IMAGE=shiftinv/overleaf-clsi:basic
FROM $BASE_IMAGE

USER root

# fix openjdk install on debian slim (see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199)
RUN mkdir -p /usr/share/man/man1

# install sage
RUN apt-get update \
 && apt-get install -y --no-install-recommends sagemath python-tk patch \
 && apt-get clean \
 && find /var/lib/apt/lists/ /tmp/ /var/tmp/ -mindepth 1 -maxdepth 1 -exec rm -rf "{}" +

# install sagetex
ARG SAGETEX_PATH=/usr/local/texlive/texmf-local/tex/latex/sagetex
ARG SAGETEXSCRIPTS_PATH=/usr/local/texlive/texmf-local/scripts/sagetex

COPY *.patch /patches/
RUN wget https://github.com/sagemath/sagetex/releases/download/v3.4/sagetex-3.4.tar.gz \
 && tar -xf sagetex-3.4.tar.gz \
## patch files
 && patch sagetex-3.4/run-sagetex-if-necessary.py < /patches/run-sagetex-if-necessary.py.patch \
 && patch sagetex-3.4/sagetex.py < /patches/sagetex.py.patch \
 && rm -rf /patches \
## copy sty
 && mkdir -p $SAGETEX_PATH \
 && mv sagetex-3.4/sagetex.sty $SAGETEX_PATH/sagetex.sty \
 && mktexlsr \
## copy python files
 && mkdir -p $SAGETEXSCRIPTS_PATH \
 && mv sagetex-3.4/run-sagetex-if-necessary.py $SAGETEXSCRIPTS_PATH/run-sagetex-if-necessary.py \
 && mv sagetex-3.4/sagetex.py /usr/lib/python2.7/dist-packages/ \
 && rm -rf sagetex-3.4 sagetex-3.4.tar.gz

COPY ./run-sagetex-custom.py $SAGETEXSCRIPTS_PATH/run-sagetex-custom.py

# autorun sagetex using latexmk
#   %T = name of .tex file
#   %R = jobname ('output')
#   %Z = output directory
ARG SAGETEX_COMMAND="{  [ ! -f %Z%R.sagetex.sage ] || python $SAGETEXSCRIPTS_PATH/run-sagetex-custom.py %T %R %Z 1>>%Z%R.sagetex.stdout.log 2>>%Z%R.sagetex.stderr.log; }"
RUN echo "\$latex = \"\$latex && $SAGETEX_COMMAND\";\n\$pdflatex = \"\$pdflatex && $SAGETEX_COMMAND\";" >> "$LATEXMKRCSYS"


USER node
