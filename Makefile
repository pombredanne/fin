JSBIN := ../mutext/node_modules/.bin
COFFEE ?= $(JSBIN)/coffee

JS = util widgets fin
BUILT := d3.js react.js fin.js open-sans.css style.css view.html \
  open-sans-bold.woff open-sans-italic.woff open-sans.woff

.PHONY: all test clean

all: $(BUILT:%=build/%) fin

build:
	mkdir build

build/d3.js: third_party/d3/d3.v3.min.js | build
	cp $^ $@

build/react.js: third_party/react/react-0.11.1.js | build
	cp $^ $@

build/fin.js: $(JS:%=src/fin/web/%.coffee) | build
	cat $^ | $(COFFEE) -c -s > $@

build/%: src/fin/web/% | build
	cp $^ $@

fin: src/*/*.go
	GOPATH=`pwd` go build fin

test:
	GOPATH=`pwd` go test fin/... bank/...

clean:
	rm -rf build fin
