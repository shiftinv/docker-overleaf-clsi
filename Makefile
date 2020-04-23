# Makefile

build:
	docker build -f Dockerfile -t shiftinv/sharelatex-clsi:basic .

.PHONY: build
