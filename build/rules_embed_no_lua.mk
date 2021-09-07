LUA_ENABLE    = 0

LUA           = lua-5.3.5
CFLAGS_STATIC = -static 
#-static-libgcc -static-libstdc++
CFLAGS        = -std=c++11 -Istlport -fno-exceptions -fno-rtti $(CFLAGS_STATIC) -I. -Os -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DNO_SQLITE -DNO_LIBUUID
OBJS          = main.o common.o ssdp.o soap.o soap_int.o http.o db_mem.o scan.o mime.o charset.o live.o md5.o newdelete.o \
 compat.o plugin_hls_common.o plugin_hls.o plugin_hls_new.o plugin_tsbuf.o plugin_udprtp.o plugin_tsfilter.o

ifeq ($(LUA_ENABLE), 1)
$(info Lua is enabled)
CFLAGS        += -I$(LUA)
OBJS          += scripting.o luajson.o plugin_lua.o
LIBS          += $(LUA)/liblua.a \
 $(STAGING_DIR)/toolchain-mipsel_24kc_gcc-5.4.0_uClibc-1.0.14/lib/libm.a \
 $(STAGING_DIR)/toolchain-mipsel_24kc_gcc-5.4.0_uClibc-1.0.14/lib/libdl.a
# $(STAGING_DIR)/../build_dir/toolchain-mipsel_24kc_gcc-5.4.0_uClibc-1.0.14/uClibc-ng-1.0.14/ldso/libdl/libdl_so.a
else
$(info Lua is not enabled)
CFLAGS        += -DNO_LUA
endif

all: version $(LIBS) $(OBJS)
	PATH=$(PATH):$(LIBEXEC) STAGING_DIR=$(STAGING_DIR) $(CC) -B $(LIBEXEC) $(CFLAGS_STATIC) -o xupnpd $(OBJS) $(LIBS)
#	PATH=$(PATH):$(LIBEXEC) STAGING_DIR=$(STAGING_DIR) $(CC) -B $(LIBEXEC) -o xupnpd $(OBJS) $(LIBS) -Wl,-E -lm -ldl
	$(STRIP) xupnpd

$(LUA)/liblua.a:
	$(MAKE) -C $(LUA) a CC=$(CC) PATH=$(PATH):$(LIBEXEC) STAGING_DIR=$(STAGING_DIR) MYCFLAGS="-DLUA_USE_LINUX -Os"

version:
	./ver.sh

clean:
	$(MAKE) -C $(LUA) clean
	$(RM) -f $(OBJS) xupnpd.db xupnpd version.h

.c.o:
	PATH=$(PATH):$(LIBEXEC) STAGING_DIR=$(STAGING_DIR) $(CC) $(CFLAGS_STATIC) -c -o $@ $<

.cpp.o:
	PATH=$(PATH):$(LIBEXEC) STAGING_DIR=$(STAGING_DIR) $(CPP) -c $(CFLAGS) -o $@ $<

