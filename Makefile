# ***********************************************************************
#
# $HeadURL: https://www.mech.kth.se/svn/simson/trunk/Makefile $
# $LastChangedDate: 2007-11-23 13:19:20 +0100 (Fri, 23 Nov 2007) $
# $LastChangedBy: mattias@MECH.KTH.SE $
# $LastChangedRevision: 960 $
#
# ***********************************************************************

#
# Makefile for Simson
#

# Sub directories
SUBDIRS = \
bla \
bls \
cmp \
fou \
lambda2 \
pamp \
pext1 \
pxyst \
rit \
rps \
xys_add

# Reduced set of sub directories
SUBDIRS_REDUCED = \
bla \
bls \
rit \
pxyst

# Gobal configuration file
include config.mk

# Gobal rule file
include rules.mk

plain: 	$(SUBDIRS:%=%.all)
	@echo '-------------------------------------------------------------------'
	@echo ''
	@echo ' Simson was built successfully! Note that already compiled files'
	@echo ' have not been rebuilt and that local par.f files have been used.'
	@echo ' Use option "all" to achieve complete build with global par.f.'
	@echo ''
	@MAKE=$(MAKE) && \
	echo  " Type \"$${MAKE##*/} install\" to install Simson into"
	@echo " $(prefix)/bin/ "
	@echo ''
	@echo ' The installation directory can be changed with'
	@echo ' the --prefix option to ./configure, or by giving a'
	@echo ' new value on the command line to "make install", e.g.'
	@MAKE=$(MAKE) && \
	echo '' && \
	echo  " $${MAKE##*/} prefix=/opt/local install"
	@echo ''
	@echo '-------------------------------------------------------------------'

red: 	$(SUBDIRS_REDUCED:%=%.all)
	@echo '-------------------------------------------------------------------'
	@echo ''
	@echo ' Reduced Simson was built successfully! Note that already'
	@echo ' compiled files have not been rebuilt and that local par.f files'
	@echo ' have been used. Use option "allred" to achieve reduced build with'
	@echo ' global par.f.'
	@echo ''
	@MAKE=$(MAKE) && \
	echo  " Type \"$${MAKE##*/} install\" to install Simson into"
	@echo " $(prefix)/bin/ "
	@echo ''
	@echo ' The installation directory can be changed with'
	@echo ' the --prefix option to ./configure, or by giving a'
	@echo ' new value on the command line to "make install", e.g.'
	@MAKE=$(MAKE) && \
	echo '' && \
	echo  " $${MAKE##*/} prefix=/opt/local install"
	@echo ''
	@echo '-------------------------------------------------------------------'


all:    $(SUBDIRS:%=%.clean) $(SUBDIRS:%=%.dist) $(SUBDIRS:%=%.all)
	@echo '-------------------------------------------------------------------'
	@echo ''
	@echo ' The complete Simson package was built successfully!'
	@echo ''
	@MAKE=$(MAKE) && \
	echo  " Type \"$${MAKE##*/} install\" to install Simson into"
	@echo " $(prefix)/bin/ "
	@echo ''
	@echo ' The installation directory can be changed with'
	@echo ' the --prefix option to ./configure, or by giving a'
	@echo ' new value on the command line to "make install", e.g.'
	@MAKE=$(MAKE) && \
	echo '' && \
	echo  " $${MAKE##*/} prefix=/opt/local install"
	@echo ''
	@echo '-------------------------------------------------------------------'

allred:	$(SUBDIRS_REDUCED:%=%.clean) $(SUBDIRS_REDUCED:%=%.dist) $(SUBDIRS_REDUCED:%=%.all)
	@echo '-------------------------------------------------------------------'
	@echo ''
	@echo ' Reduced Simson was built successfully!'
	@echo ''
	@MAKE=$(MAKE) && \
	echo  " Type \"$${MAKE##*/} install\" to install Simson into"
	@echo " $(prefix)/bin/ "
	@echo ''
	@echo ' The installation directory can be changed with'
	@echo ' the --prefix option to ./configure, or by giving a'
	@echo ' new value on the command line to "make install", e.g.'
	@MAKE=$(MAKE) && \
	echo '' && \
	echo  " $${MAKE##*/} prefix=/opt/local install"
	@echo ''
	@echo '-------------------------------------------------------------------'


clean:  $(SUBDIRS:%=%.clean) doc.clean

cleanred: $(SUBDIRS_REDUCED:%=%.clean) doc.clean

doc:
	@cd doc; make

dist:   $(SUBDIRS:%=%.dist)

distred:$(SUBDIRS_REDUCED:%=%.dist)

install:$(SUBDIRS:%=%.install)

installred:$(SUBDIRS_REDUCED:%=%.install)

test:
	@cd test; make test

release:
	tar cvf simson-release.tar Makefile config config.mk rules.mk \
	bla/*.f bla/Makefile* \
	bls/*.f bls/Makefile* \
	cmp/*.f cmp/Makefile* \
	fou/*.f fou/Makefile* \
	lambda2/*.f lambda2/Makefile* lambda2/*.net \
	pamp/*.f pamp/Makefile* \
	pxyst/*.f pxyst/Makefile* \
	rit/*.f rit/Makefile* \
	rps/*.f rps/Makefile* \
	xys_add/*.f xys_add/Makefile*
