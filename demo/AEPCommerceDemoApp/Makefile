
# simulator architectures
ARCH_X86_64 = x86_64
# i386 == 32-bit simulator - cocoapods complains when this is missing so leaving it in
ARCH_I386 = i386

# platforms
SDK_IOS = iphoneos
SDK_IOS_SIMULATOR = iphonesimulator

# configurations
BUILD_IOS_TARGET_VERSION = IPHONEOS_DEPLOYMENT_TARGET=10.0
BUILDFLAGS_BITCODE = BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS='-fembed-bitcode -Wno-error=unused-command-line-argument'
BUILDFLAGS = GCC_TREAT_WARNINGS_AS_ERRORS=YES GCC_GENERATE_DEBUGGING_SYMBOLS=NO STRIP_INSTALLED_PRODUCT=YES STRIP_STYLE=ALL GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS NDEBUG=1 NS_BLOCK_ASSERTIONS=1 COMPILEFORAPP'
DERIVED_DATA = -derivedDataPath
DESTINATION = -destination
RELEASE = -configuration Release
TIMESTAMP = $(shell date "+%m%d_%H%M")
XCODEBUILD = xcodebuild

# directories
BIN_DIR = $(ROOT_DIR)/bin/iOS/
OUT_DIR = $(ROOT_DIR)/out/
BUILD_DIR = Build/
BUILD_TEMP_DIR = $(BIN_DIR)appbuild/
DOC_DIR = $(ROOT_DIR)/doc
INCLUDE_DIR = $(ROOT_DIR)/code/src/include
PRODUCTS_DIR = Products/
RELEASE_DIR_IPHONE = $(BUILD_DIR)$(PRODUCTS_DIR)Release-$(SDK_IOS)/
RELEASE_DIR_SIMULATOR = $(BUILD_DIR)$(PRODUCTS_DIR)Release-$(SDK_IOS_SIMULATOR)/
ROOT_DIR = $(shell git rev-parse --show-toplevel)

LIB_VERSION = $(shell grep 'private static let version' $(ROOT_DIR)/code/src/ExperiencePlatformInternal.swift | sed 's/.*private static let version.*=.*\"\(.*\)\".*/\1/')
APP_NAME = AEPCommerceDemoApp
EXTENSION_NAME = AEPExperiencePlatform
DEMO_DIR = $(ROOT_DIR)/demo/
APP_DIR = $(DEMO_DIR)$(APP_NAME)/
LIBS_DIR = $(APP_DIR)libs/
LIB_NAME = lib$(EXTENSION_NAME).a
LIB_SWIFT_MODULE_NAME = $(EXTENSION_NAME).swiftmodule

# environments
WORKSPACE_NAME = $(APP_NAME).xcworkspace
PROJECT_FILE = $(APP_NAME).xcodeproj
BUILD_SCHEME = $(APP_NAME)
TEST_DERIVED_DATA_PATH = $(APP_NAME)/out

build-shallow: clean clean-libs copy-libs x86_64


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

archive-app:
	@echo "######################################################################"
	@echo "### Zip Demo App"
	@echo "######################################################################"

	cd $(DEMO_DIR) && zip -r -9 $(OUT_DIR)$(APP_NAME)-$(LIB_VERSION).zip \
		$(APP_NAME)/$(APP_NAME) \
		$(APP_NAME)/$(APP_NAME).xcodeproj \
		$(APP_NAME)/$(APP_NAME).xcworkspace \
		$(APP_NAME)/xdmlib \
		$(APP_NAME)/Podfile \
		$(APP_NAME)/libs \
		-x *xcuserdata* *.gitignore* *.a *.swiftmodule*

clean-libs:
	@echo "######################################################################"
	@echo "### Clean Demo App Libs"
	@echo "######################################################################"

	rm -f $(LIBS_DIR)$(LIB_NAME)
	rm -rf $(LIBS_DIR)$(LIB_SWIFT_MODULE_NAME)

copy-libs: clean-libs
	@echo "######################################################################"
	@echo "### Copy Demo App Libs"
	@echo "######################################################################"

	cp -R $(BIN_DIR)$(LIB_SWIFT_MODULE_NAME) $(LIBS_DIR)$(LIB_SWIFT_MODULE_NAME)
	cp $(BIN_DIR)$(LIB_NAME) $(LIBS_DIR)$(LIB_NAME)

clean:
	@echo "######################################################################"
	@echo "### Cleaning App..."
	@echo "######################################################################"

	-rm -rf $(BUILD_TEMP_DIR)

