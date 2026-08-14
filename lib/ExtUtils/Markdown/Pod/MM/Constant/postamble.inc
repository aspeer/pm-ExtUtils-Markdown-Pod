#  Targets that invoke the module 
#
MARKPOD_TARGETS=

.PHONY: doc readme $(MARKPOD_TARGETS)


#  Call modules with different method
#
MARKPOD_PERL_TARGET=$(PERLRUN) -MExtUtils::Markdown::Pod::MM \
		-e 'my $$method=pop @ARGV; ExtUtils::Markdown::Pod::MM->$$method(@ARGV)' \
		-- "$(NAME)" "$(NAME_SYM)" "$(DISTNAME)" "$(DISTVNAME)" "$(VERSION)" "$(VERSION_SYM)" "$(VERSION_FROM)" "$(LICENSE)" "$(AUTHOR)" "$(TO_INST_PM)" "$(EXE_FILES)" "$(DIST_DEFAULT_TARGET)" "$(SUFFIX)" "$(ABSTRACT_FROM)" $(MAKECMDGOALS)


#  Targets that can run without rebuiling Makefile
#
$(MARKPOD_TARGETS) ::
	@$(MARKPOD_PERL_TARGET)

doc :: readme
	@$(MARKPOD_PERL_TARGET)

readme ::
	@$(MARKPOD_PERL_TARGET) readme
