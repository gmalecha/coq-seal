coq: Makefile.coq
	$(MAKE) -f Makefile.coq

test: coq
	$(MAKE) -C test-suite

Makefile.coq: _CoqProject
	$(COQBIN)coq_makefile -f _CoqProject -o Makefile.coq

clean: Makefile.coq
	$(MAKE) -f Makefile.coq clean
	rm -f Makefile.coq
