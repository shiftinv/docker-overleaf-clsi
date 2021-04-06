SCHEME = basic
MAIN_IMAGE = shiftinv/overleaf-clsi:$(SCHEME)

build:
	docker build -f Dockerfile -t $(MAIN_IMAGE) --build-arg _TEXLIVE_SCHEME=scheme-$(SCHEME) .

build-nocache:
	docker build -f Dockerfile -t $(MAIN_IMAGE) --build-arg _TEXLIVE_SCHEME=scheme-$(SCHEME) --build-arg _TEXLIVE_CACHEBUSTER=$(shell date +%s) .

build-sagetex: build
	docker build -f sagetex/Dockerfile -t $(MAIN_IMAGE)-sagetex --build-arg BASE_IMAGE=$(MAIN_IMAGE) sagetex

.PHONY: build build-nocache build-sagetex
