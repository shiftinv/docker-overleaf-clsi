# Makefile

build:
	docker build -f Dockerfile -t shiftinv/sharelatex-clsi:full .

.PHONY: build
