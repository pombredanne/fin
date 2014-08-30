JS := ../mutext/node_modules/.bin
COFFEE ?= $(JS)/coffee

JSFILES = d3 react code

.PHONY: all test clean

all: $(JSFILES:%=build/%.js) build/style.css build/view.html fin

build:
	mkdir -p build
	cp static/* build

build/d3.js: third_party/d3/d3.v3.min.js | build
	cp $^ $@

build/react.js: third_party/react/react-0.11.1.js | build
	cp $^ $@

build/%.js: web/%.coffee | build
	$(COFFEE) -o build -b -c $<

build/style.css: web/style.css
	cp $^ $@

build/view.html: web/view.html
	cp $^ $@

fin: src/* src/*/*
	GOPATH=`pwd` go build fin

test:
	GOPATH=`pwd` go test fin/... bank/...

clean:
	rm -rf build fin
