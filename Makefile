# Makefile

build:
	docker build -f Dockerfile -t shiftinv/overleaf-clsi:basic .

.PHONY: build
