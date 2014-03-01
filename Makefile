##############################################################################
OCAMLC = ocamlc
OCAMLOPT = ocamlopt
OCAMLFIND = ocamlfind
LIBDIR = bdb

OCAML_LIBS = $(shell $(OCAMLC) -where)

BDB_INCLUDE=/usr/include
BDB_LIBS=/usr/lib
CFLAGS=-g

#CFLAGS=-O2 -Werror-implicit-function-declaration
#-DDEBUG for debug output

#pad: use ocamlmklib ? and get rid of -custom

##############################################################################
all: bdb.cma 
all.opt: bdb.cmxa
opt: all.opt

bdb.ml: bdb.src bdberrs.src
	cat bdb.src | perl extract_caml.pl > bdb.ml
	cpp -include $(BDB_INCLUDE)/db.h bdberrs.src | perl beginend.pl >> bdb.ml

bdb_stubs.c: bdb.src
	cp bdb.src bdb_stubs.c

bdb_stubs.o: bdb_stubs.c
	gcc $(CFLAGS) -I$(BDB_INCLUDE) -I$(OCAML_LIBS) \
		-L$(BDB_LIBS) -c bdb_stubs.c

libcamlbdb.a: bdb_stubs.o 
	rm -rf libcamlbdb.a
	ar rc libcamlbdb.a bdb_stubs.o
	ranlib libcamlbdb.a 

bdb.cmo: bdb.ml
	$(OCAMLC) -c bdb.ml

bdb.cma: bdb.cmo libcamlbdb.a
	$(OCAMLC) -a -o bdb.cma -custom bdb.cmo \
		-cclib -lcamlbdb -cclib -ldb -ccopt "-L ."

clean:
	$(RM) bdb.cma bdb.cmxa libcamlbdb.a bdb_stubs.o bdbtop bdb_stubs.c \
	  bdb_stubs.a bdb.a bdb.ml *.cmo *.cmi *.cmx *.o bdb.o bdb.cmx 

##############################################################################
bdb.cmx: bdb.ml
	$(OCAMLOPT) -c bdb.ml

bdb.cmxa: bdb.cmx libcamlbdb.a
	$(OCAMLOPT) -a -o bdb.cmxa bdb.cmx \
		-cclib -lcamlbdb -cclib -ldb -ccopt "-L ."

##############################################################################
# PAD
##############################################################################
bdbo.cmo: bdbo.ml
	$(OCAMLC) -c -I .. bdbo.ml

bdbo.cmx: bdbo.ml
	$(OCAMLOPT) bdbo.ml -I .. 

test.exe: test.ml bdb.src bdb_stubs.c
	$(OCAMLC) -c test.ml
	$(OCAMLC) bdb.cma unix.cma -ccopt "-L$(BDB_LIBS)" -o $@ test.cmo

test2.exe: test.ml bdb.src bdb_stubs.c
	$(OCAMLOPT) -c -thread test.ml
	$(OCAMLOPT) -thread bdb.cmxa -ccopt "-L$(BDB_LIBS)" unix.cmxa -o $@ test.cmx

clean2: 
	$(RM) test test.cm* test.o

depend::

##############################################################################
# Find
##############################################################################
findinstall:
	$(OCAMLFIND) install $(LIBDIR) META *.a *.cm[iatx] *.cmx[as]

