export ARCHS = arm64 arm64e

export TARGET = iphone:14.5
export SDKVERSION = 14.5

export THEOS_PACKAGE_SCHEME = rootless

export iP = 192.168.1.103
export Port = 22
export Pass = alpine
export Bundle =  com.apple.springboard

include $(THEOS)/makefiles/common.mk

export TWEAK_NAME = 0Cr4shed
0Cr4shed_FILES = $(wildcard *.m *.mm *.xm Shared/*.mm)
0Cr4shed_CFLAGS = -fobjc-arc -std=c++11 -IInclude
0Cr4shed_FRAMEWORKS = CoreSymbolication
0Cr4shed_LIBRARIES = MobileGestalt rocketbootstrap 
0Cr4shed_PRIVATE_FRAMEWORKS = AppSupport 
0Cr4shed_LDFLAGS += -FFrameworks/ -LLibraries/
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN -Wno-shorten-64-to-32

include $(THEOS_MAKE_PATH)/tweak.mk


before-package::
		$(ECHO_NOTHING) chmod 755 $(CURDIR)/.theos/_/DEBIAN/*  $(ECHO_END)
		$(ECHO_NOTHING) chmod 755 $(CURDIR)/.theos/_/DEBIAN  $(ECHO_END)


after-install::
	install.exec "ldrestart"
SUBPROJECTS += cr4shedgui
SUBPROJECTS += cr4shedmach
SUBPROJECTS += cr4shedjetsam
SUBPROJECTS += frpreferences
SUBPROJECTS += cr4shedSB
SUBPROJECTS += cr4shedd

include $(THEOS_MAKE_PATH)/aggregate.mk


install6::
	install6.exec