ECFLAGS := -mfloat-abi=softfp
ELDFLAGS := -Wl,--fix-cortex-a8

NDKVER := r10d
NDK := android-ndk-$(NDKVER)
SDKAPI := 14
# NDK is preinstalled in /opt
ANDROIDNDK=/opt/$(NDK)

ifeq ($(shell uname -m),x86_64)
        export BUILD_PLATFORM=x86_64
else
        export BUILD_PLATFORM=x86
endif

TOOLCHAIN_PREFIX=arm-linux-androideabi
TOOLCHAIN_VERSION=4.9

SYSROOT := $(ANDROIDNDK)/platforms/android-$(SDKAPI)/arch-arm/
CROSS_PREFIX := $(ANDROIDNDK)/toolchains/$(TOOLCHAIN_PREFIX)-$(TOOLCHAIN_VERSION)/prebuilt/linux-$(BUILD_PLATFORM)/bin/$(TOOLCHAIN_PREFIX)-

TARGET_LIB_DIR := 
LIB_NAME := libav
BIN := avconv
BIN_COPY := $(addprefix $(TARGET_LIB_DIR),$(BIN))
LIB := libavcodec libavdevice libavfilter libavformat libavresample libavutil libswscale
LIB_COPY := $(addsuffix .so,$(addprefix $(TARGET_LIB_DIR),$(LIB)))

all: download build copy $(LIB_NAME).tar.gz

download: $(LIB_NAME)

$(LIB_NAME):
	git clone git://git.libav.org/$(LIB_NAME).git
	#wget https://libav.org/releases/libav-11.tar.xz
	#tar xf libav-11.tar.xz
	#mv libav-11 libav

build: configure download
	$(MAKE) -C $(LIB_NAME)

patch: $(LIB_NAME)/.patch_applied

$(LIB_NAME)/.patch_applied:
	cd $(LIB_NAME) && patch -Np1 -i ../libav.patch
	touch $(LIB_NAME)/.patch_applied

configure: download $(LIB_NAME)/config.h

$(LIB_NAME)/config.h: patch
	cd $(LIB_NAME) && \
	./configure --arch=arm --cross-prefix=$(CROSS_PREFIX) \
		--target-os=android --sysroot="$(SYSROOT)" --extra-cflags="$(ECFLAGS)" \
		--extra-ldflags="$(ELDFLAGS)" --enable-shared --disable-symver

copy: $(BIN_COPY) $(LIB_COPY)

$(BIN_COPY):
	#cp $(abspath $(LIB_NAME))/$(notdir $@) $@
	mkdir -p bin && cp $(abspath $(LIB_NAME))/$(notdir $@) bin/

$(LIB_COPY):
	#cp -L $(abspath $(LIB_NAME))/$(subst .so,,$(notdir $@))/$(notdir $@) $@
	mkdir -p lib && cp -L $(abspath $(LIB_NAME))/$(subst .so,,$(notdir $@))/$(notdir $@) lib

$(LIB_NAME).tar.gz:
	tar czf $(LIB_NAME).tar.gz bin/* lib/*

clean:
	-make -C $(LIB_NAME) clean
	-rm -f $(BIN_COPY)
	-rm -f $(LIB_COPY)

distclean: clean
	-rm -fr $(LIB_NAME)

.PHONY: all clean distclean
