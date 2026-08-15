#  Targets that invoke the module 
#
MARKPOD_TARGETS=


#  Always invoke targets even if no changes
#
.PHONY: doc readme $(MARKPOD_TARGETS)


#  Call modules with different method
#
#  Call module method
#
MARKPOD_PM_TARGET=$(PERLRUN) \
	-e 'my $$method=shift(@ARGV) || $@; $(MARKPOD_PM)->$$method($(MARKPOD_PM_ARGV), @ARGV)'


#  Targets that can run without rebuiling Makefile
#
$(MARKPOD_TARGETS) ::
	@$(MARKPOD_PM_TARGET)

doc ::
	@$(MARKPOD_PM_TARGET)

readme ::
	@$(MARKPOD_PM_TARGET) readme

