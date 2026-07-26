#  Targets that invoke the module 
#
MM_TARGETS=


#  Call modules with different method
#
MM_PERL_PM_TARGET=$(PERLRUN) -M$(MM_PM) \
		-e 'my $$method=(pop @ARGV) || $@; $(MM_PM)->$$method(@ARGV)' \
		-- $(MM_ARGV) $(MAKECMDGOALS)


#  Targets that can run without rebuiling Makefile
#
$(MM_TARGETS) ::
	@$(MM_PERL_PM_TARGET)

doc :: readme
	@$(MM_PERL_PM_TARGET)

readme ::
	@$(MM_PERL_PM_TARGET) readme
