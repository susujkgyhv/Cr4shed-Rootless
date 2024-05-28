INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

export THEOS_PACKAGE_SCHEME = rootless

TWEAK_NAME = Cr4shedSB
Cr4shedSB_FILES = $(wildcard *.xm)
Cr4shedSB_CFLAGS = -fobjc-arc -I../Include -Wno-unused-variable
Cr4shedSB_FRAMEWORKS = CoreSymbolication
Cr4shedSB_LIBRARIES = MobileGestalt
Cr4shedSB_PRIVATE_FRAMEWORKS = AppSupport
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN

include $(THEOS_MAKE_PATH)/tweak.mk
