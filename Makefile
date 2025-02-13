#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tvheadend
PKG_VERSION:=4.2.8
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/tvheadend/tvheadend/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=1aef889373d5fad2a7bd2f139156d4d5e34a64b6d38b87b868a2df415f01f7ad

PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILES:=LICENSE.md

PKG_FIXUP:=autoreconf

PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/nls.mk

define Package/tvheadend
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=Tvheadend is a TV streaming server for Linux
  DEPENDS:=+libopenssl +librt +zlib +libffi +TVHEADEND_AVAHI_SUPPORT:libavahi-client $(ICONV_DEPENDS)
  USERID:=tvheadend:dvb
  URL:=https://tvheadend.org
  MAINTAINER:=Marius Dinu <m95d+git@psihoexpert.ro>
endef

define Package/tvheadend/description
  Tvheadend is a TV streaming server and recorder for Linux, FreeBSD and Android
  supporting DVB-S, DVB-S2, DVB-C, DVB-T, ATSC, IPTV, SAT>IP and HDHomeRun as input sources.

  Tvheadend offers the HTTP (VLC, MPlayer), HTSP (Kodi, Movian) and SAT>IP streaming.
endef

define Package/tvheadend/config
  menu "Configuration"
  depends on PACKAGE_tvheadend
  source "$(SOURCE)/Config.in"
  endmenu
endef

# Generic build options
ifneq ($(CONFIG_PKG_ASLR_PIE_NONE),)
  CONFIGURE_ARGS += --disable-pie
endif

# TV sources
ifeq ($(CONFIG_TVHEADEND_LINUXDVB_SUPPORT),)
  CONFIGURE_ARGS += --disable-linuxdvb
endif

ifeq ($(CONFIG_TVHEADEND_DVBSCAN_SUPPORT),)
  CONFIGURE_ARGS += --disable-dvbscan
endif

ifeq ($(CONFIG_TVHEADEND_IPTV),)
  CONFIGURE_ARGS += --disable-iptv
endif

ifeq ($(CONFIG_TVHEADEND_SATIP_SERVER),)
  CONFIGURE_ARGS += --disable-satip_server
endif

ifeq ($(CONFIG_TVHEADEND_SATIP_CLIENT),)
  CONFIGURE_ARGS += --disable-satip_client
endif

ifeq ($(CONFIG_TVHEADEND_HDHOMERUN_CLIENT),)
  CONFIGURE_ARGS += --disable-hdhomerun_static
else
  CONFIGURE_ARGS += --enable-hdhomerun_client
endif

# Descrambling
ifeq ($(CONFIG_TVHEADEND_CWC_SUPPORT),)
  CONFIGURE_ARGS += --disable-cwc
endif

ifeq ($(CONFIG_TVHEADEND_CAPMT_SUPPORT),)
  CONFIGURE_ARGS += --disable-capmt
endif

ifeq ($(CONFIG_TVHEADEND_CCW_SUPPORT),)
  CONFIGURE_ARGS += --disable-constcw
endif

# Other options
ifeq ($(CONFIG_TVHEADEND_AVAHI_SUPPORT),)
  CONFIGURE_ARGS += --disable-avahi
else
  CONFIGURE_ARGS += --enable-avahi
endif

ifeq ($(CONFIG_TVHEADEND_IMAGECACHE),)
  CONFIGURE_ARGS += --disable-imagecache
else
  CONFIGURE_ARGS += --enable-imagecache
endif

ifeq ($(CONFIG_TVHEADEND_TRACE),)
  CONFIGURE_ARGS += --disable-trace
endif

# libav and ffmpeg are broken, so remove codecs too.
CONFIGURE_ARGS += \
	--arch=$(ARCH) \
	--disable-dbus_1 \
	--disable-libav \
	--disable-ffmpeg_static \
	--disable-libx264 \
	--disable-libx264_static \
	--disable-libx265 \
	--disable-libx265_static \
	--disable-libvpx \
	--disable-libvpx_static \
	--disable-libtheora \
	--disable-libtheora_static \
	--disable-libvorbis \
	--disable-libvorbis_static \
	--disable-libfdkaac \
	--disable-libfdkaac_static \
	--enable-bundle \
	--nowerror=unused-variable

define Build/Prepare
	$(call Build/Prepare/Default)
	echo 'Tvheadend $(shell echo $(PKG_SOURCE_VERSION) | sed "s/^v//")~openwrt$(PKG_RELEASE)' \
		> $(PKG_BUILD_DIR)/debian/changelog
endef

define Package/conffiles
/etc/config/tvheadend
endef

define Package/tvheadend/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/tvheadend.init $(1)/etc/init.d/tvheadend
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/tvheadend.config $(1)/etc/config/tvheadend
	$(INSTALL_DIR) $(1)/etc/hotplug.d/usb
	$(INSTALL_BIN) ./files/dvb.hotplug $(1)/etc/hotplug.d/usb/50-dvb

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build.linux/tvheadend $(1)/usr/bin/
endef

$(eval $(call BuildPackage,tvheadend))
