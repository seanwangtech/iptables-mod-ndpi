#
# Copyright (C) 2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=iptables-mod-ndpi
PKG_RELEASE:=4.0
PKG_VERSION:=1.$(PKG_RELEASE)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://opkg.baiyatech.com/repos/shs-project/
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/iptables-mod-ndpi
  SUBMENU:=Firewall
  SECTION:=net
  CATEGORY:=Network
  TITLE:=ndpi successor of OpenDPI
  URL:=http://www.ntop.org/products/ndpi/
  DEPENDS:=+iptables +iptables-mod-conntrack-extra +kmod-ipt-ndpi
  MAINTAINER:=Thomas Heil <heil@terminal-consulting.de>
endef

define Package/iptables-mod-ndpi/description
  nDPI is a ntop-maintained superset of the popular OpenDPI library
endef

define Download/ndpi-netfilter
  VERSION:=591e599642e701f1a8e15aaa2a126f806cf34304
  FILE:=ndpi-netfilter-$(PKG_VERSION).tar.gz
  URL:=https://github.com/ninglvfeihong/ndpi-netfilter.git
  PROTO:=git
  SUBDIR:=ndpi-netfilter
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	$(eval $(call Download,ndpi-netfilter))
	tar -zxvf $(DL_DIR)/ndpi-netfilter-$(PKG_VERSION).tar.gz -C $(PKG_BUILD_DIR)
endef

define Build/Configure
	(cd $(PKG_BUILD_DIR); \
		libtoolize --automake --force --copy; \
                autoreconf -ihv  || exit 1 \
        );

endef

CONFIGURE_ARGS += \
        --with-pic \
	--target=$(GNU_TARGET_NAME) \
        --host=$(GNU_TARGET_NAME) \
        --build=$(GNU_HOST_NAME) \
	LIBS=-lposix -lndpi_la-spotify.lo -lndpi_la-ahocorasick.lo 

MAKE_PATH := ndpi-netfilter

ifneq ($(CONFIG_USE_EGLIBC),)
  TARGET_CPPFLAGS += -I$(STAGING_DIR)/usr/include 
endif


MAKE_FLAGS += \
	KERNEL_DIR=$(LINUX_DIR) \
	NDPI_PATH=$(PKG_BUILD_DIR) \
	ARCH="$(LINUX_KARCH)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	all

define Package/iptables-mod-ndpi/install
	$(INSTALL_DIR) $(1)/usr/lib/iptables
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ndpi-netfilter/ipt/libxt_ndpi.so $(1)/usr/lib/iptables
endef

define KernelPackage/ipt-ndpi
  SUBMENU:=Netfilter Extensions
  TITLE:= nDPI net netfilter module
  DEPENDS:=+kmod-ipt-compat-xtables
  KCONFIG:=CONFIG_NF_CONNTRACK \
	CONFIG_NF_CONNTRACK_EVENTS=y
  FILES:= \
	$(PKG_BUILD_DIR)/ndpi-netfilter/src/xt_ndpi.ko
  AUTOLOAD:=$(call AutoLoad,46,xt_ndpi)
endef

$(eval $(call BuildPackage,iptables-mod-ndpi))
$(eval $(call KernelPackage,ipt-ndpi))
