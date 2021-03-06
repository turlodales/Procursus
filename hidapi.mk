ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += hidapi
HIDAPI_VERSION := 0.9.0
DEB_HIDAPI_V   ?= $(HIDAPI_VERSION)

hidapi-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/libusb/hidapi/archive/hidapi-$(HIDAPI_VERSION).tar.gz
	$(call EXTRACT_TAR,hidapi-$(HIDAPI_VERSION).tar.gz,hidapi-hidapi-$(HIDAPI_VERSION),hidapi)

ifneq ($(wildcard $(BUILD_WORK)/hidapi/.build_complete),)
hidapi:
	@echo "Using previously built hidapi."
else
hidapi: hidapi-setup
	cd $(BUILD_WORK)/hidapi && ./bootstrap
	cd $(BUILD_WORK)/hidapi && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/hidapi install \
		CFLAGS="$(CFLAGS) -D__OPEN_SOURCE__ -DMAC_OS_X_VERSION_MIN_REQUIRED=101500" \
		DESTDIR="$(BUILD_STAGE)/hidapi"
	+$(MAKE) -C $(BUILD_WORK)/hidapi install \
		CFLAGS="$(CFLAGS) -D__OPEN_SOURCE__ -DMAC_OS_X_VERSION_MIN_REQUIRED=101500" \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/hidapi/.build_complete
endif

hidapi-package: hidapi-stage
	# hidapi.mk Package Structure
	rm -rf $(BUILD_DIST)/libhidapi{0,-dev}
	mkdir -p $(BUILD_DIST)/libhidapi{0,-dev}/usr/lib
	
	# hidapi.mk Prep libhidapi0
	cp -a $(BUILD_STAGE)/hidapi/usr/lib/libhidapi.0.dylib $(BUILD_DIST)/libhidapi0/usr/lib

	# hidapi.mk Prep libhidapi-dev
	cp -a $(BUILD_STAGE)/hidapi/usr/lib/{pkgconfig,libhidapi.{a,dylib}} $(BUILD_DIST)/libhidapi-dev/usr/lib
	cp -a $(BUILD_STAGE)/hidapi/usr/include $(BUILD_DIST)/libhidapi-dev/usr
	
	# hidapi.mk Sign
	$(call SIGN,libhidapi0,general.xml)

	# hidapi.mk Make .debs
	$(call PACK,libhidapi0,DEB_HIDAPI_V)
	$(call PACK,libhidapi-dev,DEB_HIDAPI_V)
	
	# hidapi.mk Build cleanup
	rm -rf $(BUILD_DIST)/libhidapi{0,-dev}

.PHONY: hidapi hidapi-package
