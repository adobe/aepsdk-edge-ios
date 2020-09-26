
# simulator architectures
ARCH_X86_64 = x86_64
# i386 == 32-bit simulator - cocoapods complains when this is missing so leaving it in
ARCH_I386 = i386

# platforms
SDK_IOS = iphoneos
SDK_IOS_SIMULATOR = iphonesimulator

# configurations
BUILD_IOS_TARGET_VERSION = IPHONEOS_DEPLOYMENT_TARGET=10.0
RELEASE = -configuration Release
XCODEBUILD = xcodebuild

# directories
ROOT_DIR = $(shell git rev-parse --show-toplevel)
OUT_DIR = $(ROOT_DIR)/build/
BUILD_TEMP_DIR = $(OUT_DIR)out/appbuild/
PRODUCTS_DIR = Products/
BUILD_DIR = Build/
RELEASE_DIR_IPHONE = $(BUILD_DIR)$(PRODUCTS_DIR)Release-$(SDK_IOS)/
RELEASE_DIR_SIMULATOR = $(BUILD_DIR)$(PRODUCTS_DIR)Release-$(SDK_IOS_SIMULATOR)/

# environments
APP_NAME = AEPCommerceDemoApp
WORKSPACE_NAME = $(APP_NAME).xcworkspace
PROJECT_FILE = $(APP_NAME).xcodeproj
BUILD_SCHEME = $(APP_NAME)

build-shallow: clean x86_64


x86_64:
	@echo "######################################################################"
	@echo "### Building: "$@
	@echo "######################################################################"
	$(XCODEBUILD) $(RELEASE) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		-sdk $(SDK_IOS_SIMULATOR) \
		-arch $(ARCH_X86_64) \
		-derivedDataPath $(BUILD_TEMP_DIR) \
		$(BUILD_IOS_TARGET_VERSION)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(APP_NAME).app \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(APP_NAME)-$(ARCH_X86_64).app
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(APP_NAME).swiftmodule \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(APP_NAME)-$(ARCH_X86_64).swiftmodule

clean:
	@echo "######################################################################"
	@echo "### Cleaning App..."
	@echo "######################################################################"

	-rm -rf $(BUILD_TEMP_DIR)

