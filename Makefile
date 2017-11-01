MAKEFLAGS := -j 4

SHELL := /bin/bash

.DELETE_ON_ERROR:

PROBLEM_DESCRIPTIONS_MD := $(wildcard problems/*/description.md)
PROBLEM_DESCRIPTIONS_HTML := $(PROBLEM_DESCRIPTIONS_MD:%.md=%.html)

SAMPLE_DESCRIPTIONS_MD := $(wildcard samples/*/description.md)
SAMPLE_DESCRIPTIONS_HTML := $(SAMPLE_DESCRIPTIONS_MD:%.md=%.html)

all: problem-descriptions.pdf sample-descriptions.pdf

include $(wildcard problems/*/Makefile) $(wildcard samples/*/Makefile)

test-%:
	@for f in $(sort $(wildcard problems/$*/solutions/*.run samples/$*/solutions/*.run)); do \
		for g in $(sort $(wildcard problems/$*/tests/*.in samples/$*/tests/*.in)); do \
			if /usr/bin/time -o/tmp/lucid-programming-time -f%E colordiff -b "$${g/.in/.out}" <("$$f" < "$$g"); then \
				echo "Solution $$(basename $$f .run), Test $$(basename $$g .in): SUCCESS ($$(< /tmp/lucid-programming-time))"; \
			else \
				echo "Solution $$(basename $$f .run), Test $$(basename $$g .in): FAILURE ($$(< /tmp/lucid-programming-time))"; \
			fi \
		done \
	done

TESTS := $(shell echo problems/*/tests samples/*/tests)
.PHONY: zip-tests
zip-tests: $(TESTS:=.zip)

%/tests.zip: zip-tests.py
	(echo $@: $*/tests/*.in $*/tests/*.out; echo $*/tests/*.in $*/tests/*.out :) > $@.dep
	shopt -s nullglob; ./$< --input $*/tests/*.in --output $*/tests/*.out > $@

-include $(wildcard problems/*/tests.zip.dep samples/*/tests.zip.dep)

%/description.html: %/description.md convert.html.erb
	ruby -rerb -rnet/http -e 'puts ERB.new(File.read "convert.html.erb").result' < $< > $@

problem-descriptions.pdf: $(PROBLEM_DESCRIPTIONS_HTML) $(shell find problems -name '*.png' -o -name '*.svg')
	wkhtmltopdf -g --print-media-type $(sort $(PROBLEM_DESCRIPTIONS_HTML)) $@

sample-descriptions.pdf: $(SAMPLE_DESCRIPTIONS_HTML) $(shell find samples -name '*.png')
	wkhtmltopdf -g --print-media-type $(sort $(PROBLEM_DESCRIPTIONS_HTML)) $@

scoreboard/.npm:
	rm $(@D)/node_modules
	cd $(@D) && yarn install
	> $@

scoreboard/.tsc: scoreboard/.npm-install $(wildcard scoreboard/*.ts)
	$(@D)/node_modules/.bin/tsc -p $(@D)
	> $@

scoreboard.zip: $(shell find scoreboard) scoreboard/.npm-install scoreboard/.tsc-compile
	rm -f $@
	cd scoreboard && zip -qr ../scoreboard node_modules *.js

.PHONY: deploy-scoreboard
deploy-scoreboard: scoreboard.zip
	aws-staging --region us-west-1 lambda update-function-code --function-name competition-2017-leaderboard --zip-file fileb://$< --publish
