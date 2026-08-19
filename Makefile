ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FilzaSlop

# Zentrax Core & Exploit Files
FilzaSlop_FILES = Tweak.m \
    MCMBridge.m \
    MCMFilzaIntegration.m \
    ZentraxNetworkManager.m \
    ZentraxUI.m \
    kexploit/kexploit_opa334.m \
    kexploit/krw.m \
    kexploit/kutils.m \
    kexploit/offsets.m \
    kexploit/vnode.m \
    kpf/patchfinder.m \
    sandbox_escape.m \
    apfs_own.m

FilzaSlop_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-unused-function -Wno-arc-performSelector-leaks -Wno-error
FilzaSlop_FRAMEWORKS = Foundation UIKit CoreGraphics Security

include $(THEOS_MAKE_PATH)/tweak.mk
