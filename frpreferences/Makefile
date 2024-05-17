include $(THEOS)/makefiles/common.mk

export THEOS_PACKAGE_SCHEME = rootless

FRAMEWORK_NAME = FRPreferences

FRPreferences_FILES = $(wildcard *.m)
FRPreferences_PUBLIC_HEADERS = $(wildcard *.h)
FRPreferences_INSTALL_PATH = /Library/Frameworks
FRPreferences_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/framework.mk
