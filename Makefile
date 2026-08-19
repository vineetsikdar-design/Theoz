ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FilzaSlop

# ============================================================
# ZENTRAX CORE
# ============================================================

FilzaSlop_FILES = \
    Tweak.m \
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
    apfs_own.m \
    utils/hexdump.c

# ============================================================
# XPF SOURCE
# ============================================================

FilzaSlop_FILES += \
    XPF/src/xpf.c \
    XPF/src/common.c \
    XPF/src/decompress.c \
    XPF/src/ppl.c \
    XPF/src/non_ppl.c \
    XPF/src/bad_recovery.c

# ============================================================
# CHOMA SOURCE
# ============================================================

FilzaSlop_FILES += \
    XPF/external/ChOma/src/Base64.c \
    XPF/external/ChOma/src/BufferedStream.c \
    XPF/external/ChOma/src/CSBlob.c \
    XPF/external/ChOma/src/CodeDirectory.c \
    XPF/external/ChOma/src/DER.c \
    XPF/external/ChOma/src/DyldSharedCache.c \
    XPF/external/ChOma/src/Entitlements.c \
    XPF/external/ChOma/src/Fat.c \
    XPF/external/ChOma/src/FileStream.c \
    XPF/external/ChOma/src/Host.c \
    XPF/external/ChOma/src/MachO.c \
    XPF/external/ChOma/src/MachOLoadCommand.c \
    XPF/external/ChOma/src/MemoryStream.c \
    XPF/external/ChOma/src/PatchFinder.c \
    XPF/external/ChOma/src/PatchFinder_arm64.c \
    XPF/external/ChOma/src/Util.c \
    XPF/external/ChOma/src/arm64.c

# ============================================================
# INCLUDE PATHS
# ============================================================

export ADDITIONAL_CFLAGS = \
    -I./XPF \
    -I./XPF/src \
    -I./XPF/external/ChOma/include \
    -I./XPF/external/ChOma/src \
    -I.

export ADDITIONAL_OBJCFLAGS = \
    -I./XPF \
    -I./XPF/src \
    -I./XPF/external/ChOma/include \
    -I./XPF/external/ChOma/src \
    -I.

# ============================================================
# COMPILER FLAGS
# ============================================================

FilzaSlop_CFLAGS = \
    -fobjc-arc \
    -Wno-unused-variable \
    -Wno-unused-function \
    -Wno-arc-performSelector-leaks \
    -Wno-error \
    -I./XPF \
    -I./XPF/src \
    -I./XPF/external/ChOma/include \
    -I./XPF/external/ChOma/src \
    -I.

FilzaSlop_OBJCFLAGS = \
    -fobjc-arc \
    -Wno-unused-variable \
    -Wno-unused-function \
    -Wno-arc-performSelector-leaks \
    -Wno-error \
    -I./XPF \
    -I./XPF/src \
    -I./XPF/external/ChOma/include \
    -I./XPF/external/ChOma/src \
    -I.

# ============================================================
# FRAMEWORKS
# ============================================================

FilzaSlop_FRAMEWORKS = \
    Foundation \
    UIKit \
    CoreGraphics \
    Security

# ============================================================
# THEOS
# ============================================================

include $(THEOS_MAKE_PATH)/tweak.mk