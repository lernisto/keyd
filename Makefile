VERCMD  ?= git describe --always --dirty 2> /dev/null
VERSION := $(shell $(VERCMD) || cat VERSION)

include config.mk

DEPDIR = .d
$(shell mkdir -p $(DEPDIR) >/dev/null)
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td

COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
COMPILE.cc = $(CXX) $(DEPFLAGS) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
POSTCOMPILE = mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d

NAME:= keyparse

all: options config.h $(NAME)

options:
	@echo dwmstatus build options:
	@echo "CFLAGS   = ${CFLAGS}"
	@echo "LDFLAGS  = ${LDFLAGS}"
	@echo "CC       = ${CC}"

debug: CFLAGS += -O0 -g
debug: CPPFLAGS += -DDEBUG
debug: all

config.h:
	@echo creating $@ from config.def.h
	@cp config.def.h $@

SRC := $(wildcard *.c)
HDR := $(wildcard *.h)
OBJ := $(SRC:.c=.o)

%.o : %.c
%.o : %.c $(DEPDIR)/%.d
	$(COMPILE.c) $(OUTPUT_OPTION) $<
	$(POSTCOMPILE)

%.o : %.cc
%.o : %.cc $(DEPDIR)/%.d
	$(COMPILE.cc) $(OUTPUT_OPTION) $<
	$(POSTCOMPILE)

%.o : %.cxx
%.o : %.cxx $(DEPDIR)/%.d
	$(COMPILE.cc) $(OUTPUT_OPTION) $<
	$(POSTCOMPILE)

$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d

-include $(patsubst %,$(DEPDIR)/%.d,$(basename $(SRCS)))


install:
	mkdir -p "$(DESTDIR)$(BINPREFIX)"
	install -D $(NAME) "$(DESTDIR)$(BINPREFIX)"
	install -D doc/$(NAME).1 "$(DESTDIR)$(MANPREFIX)"/man1
	install -d "$(DESTDIR)$(DOCPREFIX)"
	cp -pr examples "$(DESTDIR)$(DOCPREFIX)"/examples

uninstall:
	rm -f "$(DESTDIR)$(BINPREFIX)"/$(NAME)
	rm -f "$(DESTDIR)$(MANPREFIX)"/man1/$(NAME).1
	rm -rf "$(DESTDIR)$(DOCPREFIX)"

doc:
	a2x -v -d manpage -f manpage -a revnumber=$(VERSION) doc/$(NAME).1.txt

clean:
	rm -f $(OBJ) $(NAME) VERSION

indent:
	indent -linux -brs -brf --line-length 200 $(SRC) $(HDR)

.PHONY: all options debug indent install uninstall doc clean
