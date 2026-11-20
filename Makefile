PAK_NAME ?= $(shell jq -r .name pak.json 2>/dev/null || echo N64)
PLATFORMS ?= tg5040 h700

PARALLEL_N64_REPO ?= https://github.com/libretro/parallel-n64.git
PARALLEL_N64_COMMIT ?= ab48ad59754e561c721ba73ef1953823639ed611

CONTAINER_RUNTIME ?= $(shell command -v docker 2>/dev/null || command -v podman 2>/dev/null || (command -v flatpak-spawn >/dev/null 2>&1 && echo "flatpak-spawn --host podman"))
ifeq (,$(CONTAINER_RUNTIME))
$(error Neither docker nor podman found in PATH)
endif

ifneq (,$(findstring podman,$(CONTAINER_RUNTIME)))
CONTAINER_MOUNT_OPTS ?= --security-opt label=disable
else
CONTAINER_MOUNT_OPTS ?=
endif

PUSH_PLATFORM ?= tg5040
PUSH_SDCARD_PATH ?= /mnt/SDCARD

BUILD_DIR := $(CURDIR)/build
SRC_DIR := $(BUILD_DIR)/parallel-n64
CORES_DIR := $(BUILD_DIR)/cores
DIST_DIR := $(CURDIR)/dist

.PHONY: all src build package release bump-version push clean distclean $(foreach p,$(PLATFORMS),build-$(p))

all: release

src: $(SRC_DIR)/.patched

$(SRC_DIR)/.patched: $(wildcard $(CURDIR)/patches/*.patch)
	@mkdir -p $(BUILD_DIR)
	@if [ ! -d "$(SRC_DIR)/.git" ]; then \
		echo "Cloning $(PARALLEL_N64_REPO)..."; \
		git clone $(PARALLEL_N64_REPO) $(SRC_DIR); \
	fi
	@echo "Checking out $(PARALLEL_N64_COMMIT)..."
	@git -C $(SRC_DIR) checkout -q -- .
	@git -C $(SRC_DIR) checkout -q $(PARALLEL_N64_COMMIT)
	@echo "Applying patches..."
	@for p in $(CURDIR)/patches/*.patch; do \
		[ -f "$$p" ] || continue; \
		if git -C $(SRC_DIR) apply -R --check "$$p" >/dev/null 2>&1; then \
			echo "Patch $$(basename "$$p") already applied"; \
		elif git -C $(SRC_DIR) apply --check "$$p" >/dev/null 2>&1; then \
			echo "Applying patch $$(basename "$$p")"; \
			git -C $(SRC_DIR) apply "$$p"; \
		else \
			echo "Error: Failed to apply patch $$p"; exit 1; \
		fi; \
	done
	@touch $(SRC_DIR)/.patched

build: $(foreach p,$(PLATFORMS),build-$(p))

define BUILD_PLATFORM_RULE
build-$(1): src
	@echo "Building parallel_n64_libretro.so for $(1)..."
	@mkdir -p $(CORES_DIR)/$(1)
	$$(CONTAINER_RUNTIME) run --rm $$(CONTAINER_MOUNT_OPTS) \
		-v $$(CURDIR):/workspace:rw \
		ghcr.io/loveretro/$(1)-toolchain:latest \
		bash -euc '\
			git config --global --add safe.directory "*" && \
			cd /workspace/build/parallel-n64 && \
			rm -f parallel_n64_libretro.so && \
			find . \( -name "*.o" -o -name "*.d" \) -delete && \
			export CFLAGS="-mcpu=cortex-a53 -mtune=cortex-a53" && \
			export CXXFLAGS="-mcpu=cortex-a53 -mtune=cortex-a53" && \
			export LDFLAGS="-mcpu=cortex-a53 -mtune=cortex-a53" && \
			make -j$$$$(nproc) \
				platform=unix \
				ARCH=aarch64 \
				WITH_DYNAREC=aarch64 \
				GLES=1 \
				GLES3=1 \
				HAVE_PARALLEL=0 \
				HAVE_PARALLEL_RSP=0 \
				HAVE_GLIDEN64=0 \
				HAVE_GLN64=0 \
				HAVE_THR_AL=0 \
				HAVE_GLIDE64=1 \
				HAVE_RICE=1 \
				CC=/opt/aarch64-nextui-linux-gnu/bin/aarch64-nextui-linux-gnu-gcc \
				CXX=/opt/aarch64-nextui-linux-gnu/bin/aarch64-nextui-linux-gnu-g++ \
				AR=/opt/aarch64-nextui-linux-gnu/bin/aarch64-nextui-linux-gnu-ar \
				CC_AS=/opt/aarch64-nextui-linux-gnu/bin/aarch64-nextui-linux-gnu-gcc && \
			mkdir -p /workspace/build/cores/$(1) && \
			cp parallel_n64_libretro.so /workspace/build/cores/$(1)/parallel_n64_libretro.so && \
			/opt/aarch64-nextui-linux-gnu/bin/aarch64-nextui-linux-gnu-strip --strip-unneeded /workspace/build/cores/$(1)/parallel_n64_libretro.so && \
			chmod 0755 /workspace/build/cores/$(1)/parallel_n64_libretro.so \
		'
endef

$(foreach p,$(PLATFORMS),$(eval $(call BUILD_PLATFORM_RULE,$(p))))

package:
	@echo "Packaging $(PAK_NAME).pak.zip and platform distributions..."
	@mkdir -p $(DIST_DIR)
	@rm -rf $(BUILD_DIR)/staging $(DIST_DIR)/$(PAK_NAME).pak.zip
	@mkdir -p $(BUILD_DIR)/staging/cores/tg5040 $(BUILD_DIR)/staging/cores/h700
	@cp pak.json launch.sh default*.cfg LICENSE README.md $(BUILD_DIR)/staging/
	@chmod 0755 $(BUILD_DIR)/staging/launch.sh
	@cp $(CORES_DIR)/tg5040/parallel_n64_libretro.so $(BUILD_DIR)/staging/cores/tg5040/
	@cp $(CORES_DIR)/h700/parallel_n64_libretro.so $(BUILD_DIR)/staging/cores/h700/
	@cd $(BUILD_DIR)/staging && zip -r $(DIST_DIR)/$(PAK_NAME).pak.zip .
	@mkdir -p $(DIST_DIR)/Emus/tg5040/$(PAK_NAME).pak $(DIST_DIR)/Emus/h700/$(PAK_NAME).pak
	@cp launch.sh $(DIST_DIR)/Emus/tg5040/$(PAK_NAME).pak/
	@chmod 0755 $(DIST_DIR)/Emus/tg5040/$(PAK_NAME).pak/launch.sh
	@cp default-smartpro.cfg $(DIST_DIR)/Emus/tg5040/$(PAK_NAME).pak/default.cfg
	@cp default-smartpro.cfg default-smartpros.cfg default-brick.cfg default-brickpro.cfg $(DIST_DIR)/Emus/tg5040/$(PAK_NAME).pak/
	@cp $(CORES_DIR)/tg5040/parallel_n64_libretro.so $(DIST_DIR)/Emus/tg5040/$(PAK_NAME).pak/
	@cp launch.sh $(DIST_DIR)/Emus/h700/$(PAK_NAME).pak/
	@chmod 0755 $(DIST_DIR)/Emus/h700/$(PAK_NAME).pak/launch.sh
	@cp default.cfg $(DIST_DIR)/Emus/h700/$(PAK_NAME).pak/default.cfg
	@cp $(CORES_DIR)/h700/parallel_n64_libretro.so $(DIST_DIR)/Emus/h700/$(PAK_NAME).pak/
	@echo "Successfully packaged $(DIST_DIR)/$(PAK_NAME).pak.zip"

release: build package

bump-version:
ifneq ($(strip $(RELEASE_VERSION)),)
	@jq --arg v "$(RELEASE_VERSION)" '.version = ($$v | sub("^v"; ""))' pak.json > pak.json.tmp && mv pak.json.tmp pak.json
	@echo "Version bumped to $$(jq -r .version pak.json)"
endif

push: release
	adb push $(DIST_DIR)/Emus/$(PUSH_PLATFORM)/$(PAK_NAME).pak/. $(PUSH_SDCARD_PATH)/Emus/$(PUSH_PLATFORM)/$(PAK_NAME).pak

clean:
	rm -rf $(BUILD_DIR)/cores $(BUILD_DIR)/staging $(DIST_DIR)
	@if [ -d "$(SRC_DIR)" ]; then \
		rm -f $(SRC_DIR)/parallel_n64_libretro.so; \
		find $(SRC_DIR) \( -name '*.o' -o -name '*.d' \) -delete; \
	fi

distclean: clean
	rm -rf $(BUILD_DIR)
