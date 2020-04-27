# architectures
# source: https://en.wikipedia.org/wiki/List_of_iOS_devices#RAM,_Processor,_and_Highest_supported_iOS_release

# device architectures
ARCH_ARM64 = arm64
ARCH_ARMV7S = armv7s
# armv7 == 32-bit processor - used in iPhone 5 and iPhone 5c, which can run up to iOS 10.3.3...so we have to leave it in for now
ARCH_ARMV7 = armv7

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

CLANG_ENABLE_CODE_COVERAGE = sed -i '' 's/CLANG_ENABLE_CODE_COVERAGE = NO/CLANG_ENABLE_CODE_COVERAGE = YES/g' $(PROJECT_FILE)/project.pbxproj
GENERATE_COVERAGE_FILES = sed -i '' 's/GCC_GENERATE_TEST_COVERAGE_FILES = NO/GCC_GENERATE_TEST_COVERAGE_FILES = YES/g' $(PROJECT_FILE)/project.pbxproj
GENERATE_PROGRAM_FLOW = sed -i '' 's/GCC_INSTRUMENT_PROGRAM_FLOW_ARCS = NO/GCC_INSTRUMENT_PROGRAM_FLOW_ARCS = YES/g' $(PROJECT_FILE)/project.pbxproj
DO_NOT_GENERATE_COVERAGE_FILES = sed -i '' 's/GCC_GENERATE_TEST_COVERAGE_FILES = YES/GCC_GENERATE_TEST_COVERAGE_FILES = NO/g' $(PROJECT_FILE)/project.pbxproj
DO_NOT_GENERATE_PROGRAM_FLOW = sed -i '' 's/GCC_INSTRUMENT_PROGRAM_FLOW_ARCS = YES/GCC_INSTRUMENT_PROGRAM_FLOW_ARCS = NO/g' $(PROJECT_FILE)/project.pbxproj
ENABLE_CODE_COVERAGE = $(GENERATE_COVERAGE_FILES) && $(GENERATE_PROGRAM_FLOW) && $(CLANG_ENABLE_CODE_COVERAGE)
DISABLE_CODE_COVERAGE = $(DO_NOT_GENERATE_COVERAGE_FILES) && $(DO_NOT_GENERATE_PROGRAM_FLOW)

RELEASE = -configuration Release

TEST_DERIVED_DATA = $(DERIVED_DATA) '$(TEST_DERIVED_DATA_PATH)'
TEST_DESTINATION = $(DESTINATION) 'platform=iOS Simulator,name=iPhone 8'
TIMESTAMP = $(shell date "+%m%d_%H%M")
XCODEBUILD = xcodebuild
XCODEBUILD_VERSION_MAJOR = $(shell xcodebuild -version | grep Xcode | sed 's/Xcode[[:space:]]*\([0-9]*\)\..*/\1/')
XCODEBUILD_VERSION_MINOR = $(shell xcodebuild -version | grep Xcode | sed 's/Xcode[[:space:]]*\([0-9]*\)\.\([0-9]*\).*/\2/')
XCODEBUILD_COMPATIBLE = $(shell [[ $(XCODEBUILD_VERSION_MAJOR) -gt 10  ||  ($(XCODEBUILD_VERSION_MAJOR) -eq 10) && ($(XCODEBUILD_VERSION_MINOR) -ge 2) ]] && echo true)

# directories
BIN_DIR = $(ROOT_DIR)/bin/iOS/
BUILD_DIR = Build/
BUILD_TEMP_DIR = $(BIN_DIR)build_temp/
DEV_BUILD_DIR = devbuild
DOC_DIR = $(ROOT_DIR)/doc
INCLUDE_DIR = $(ROOT_DIR)/code/src/include
LIBRARY_NAME = $(LIB_BASE_NAME)/
PRODUCTS_DIR = Products/
RELEASE_DIR_IPHONE = $(BUILD_DIR)$(PRODUCTS_DIR)Release-$(SDK_IOS)/
RELEASE_DIR_SIMULATOR = $(BUILD_DIR)$(PRODUCTS_DIR)Release-$(SDK_IOS_SIMULATOR)/
ROOT_DIR = $(shell git rev-parse --show-toplevel)

# environments
WORKSPACE_NAME = $(EXTENSION_NAME).xcworkspace
PROJECT_FILE = $(EXTENSION_NAME).xcodeproj
BUILD_SCHEME = $(EXTENSION_NAME)
TEST_DERIVED_DATA_PATH = $(EXTENSION_NAME)/out
FUNCTIONAL_TEST_SCHEME = functionalTests
TEST = test

# files
DOCUMENTATION = documentation.html
LIB_BASE_NAME = lib$(EXTENSION_NAME)
LICENSE_FILE = LICENSE.md
LIPO_LIB_PHONE = $(BUILD_DIR)$(LIB_BASE_NAME)
RELEASE_NOTES = ReleaseNotes.txt
UNIT_TEST_REPORT = $(TEST_DERIVED_DATA_PATH)/build/reports/iosUnitTestReport
UNIT_TEST_REPORT_HTML = $(UNIT_TEST_REPORT).html
UNIT_TEST_REPORT_XML = $(UNIT_TEST_REPORT).xml
FUNCTIONAL_TEST_REPORT = $(TEST_DERIVED_DATA_PATH)/build/reports/FunctionalTests/iosFunctionalTestReport
FUNCTIONAL_TEST_REPORT_HTML = $(FUNCTIONAL_TEST_REPORT).html
FUNCTIONAL_TEST_REPORT_XML = $(FUNCTIONAL_TEST_REPORT).xml
# targets
check-xcode-version:
	# check xcodebuild version (requires version 10.2)
	@echo "build version: " $(XCODEBUILD_VERSION_MAJOR).$(XCODEBUILD_VERSION_MINOR)
ifeq ($(XCODEBUILD_COMPATIBLE),true)
	@echo "Running make with xcodebuild version:" $(XCODEBUILD_VERSION_MAJOR).$(XCODEBUILD_VERSION_MINOR)
else
	$(error Failed to run make, incompatible xcodebuild version (requires 10.2 or higher))
endif

all: check-xcode-version clean arm64 armv7s armv7 x86_64 i386 lipo copy-files

all-no-clean: check-xcode-version arm64 armv7s armv7 i386 x86_64 lipo copy-files

build-shallow: check-xcode-version x86_64

armv7:
	@echo "######################################################################"
	@echo "### Building: "$@
	@echo "######################################################################"
	$(XCODEBUILD) $(RELEASE) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		-sdk $(SDK_IOS) \
		-arch $(ARCH_ARMV7) \
		-derivedDataPath $(BUILD_TEMP_DIR) \
		$(BUILD_IOS_TARGET_VERSION) $(BUILDFLAGS_BITCODE) $(BUILDFLAGS)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARMV7).a

armv7s:
	@echo "######################################################################"
	@echo "### Building: "$@
	@echo "######################################################################"
	$(XCODEBUILD) $(RELEASE) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		-sdk $(SDK_IOS) \
		-arch $(ARCH_ARMV7S) \
		-derivedDataPath $(BUILD_TEMP_DIR) \
		$(BUILD_IOS_TARGET_VERSION) $(BUILDFLAGS_BITCODE) $(BUILDFLAGS)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARMV7S).a

arm64:
	@echo "######################################################################"
	@echo "### Building: "$@
	@echo "######################################################################"
	$(XCODEBUILD) $(RELEASE) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		-sdk $(SDK_IOS) \
		-arch $(ARCH_ARM64) \
		-derivedDataPath $(BUILD_TEMP_DIR) \
		$(BUILD_IOS_TARGET_VERSION) $(BUILDFLAGS_BITCODE) $(BUILDFLAGS)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARM64).a

i386:
	@echo "######################################################################"
	@echo "### Building: "$@
	@echo "######################################################################"
	$(XCODEBUILD) $(RELEASE) \
	  -workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		-sdk $(SDK_IOS_SIMULATOR) \
		-arch $(ARCH_I386) \
		-derivedDataPath $(BUILD_TEMP_DIR) \
		$(BUILD_IOS_TARGET_VERSION) $(BUILDFLAGS)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME)-$(ARCH_I386).a

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
		$(BUILD_IOS_TARGET_VERSION) $(BUILDFLAGS)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME)-$(ARCH_X86_64).a

lipo:
	@echo "######################################################################"
	@echo "### Running: "$@
	@echo "######################################################################"
	@echo "Making binaries so fat right now..."
	xcrun lipo -create \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARMV7S).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARMV7).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARM64).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME)-$(ARCH_X86_64).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME)-$(ARCH_I386).a \
		-output $(BIN_DIR)$(LIB_BASE_NAME).a
	@echo "============================================================"
	@echo "Universal binary created:"
	@echo $(LIB_BASE_NAME).a
	lipo -info $(BIN_DIR)$(LIB_BASE_NAME).a
	@echo "============================================================"

copy-files:
	@echo "######################################################################"
	@echo "### Copying files"
	@echo "######################################################################"

	mv $(BIN_DIR)$(LIB_BASE_NAME).a $(BIN_DIR)/$(LIB_BASE_NAME).a
	#cp -r $(INCLUDE_DIR) $(BIN_DIR)/include
	rm -rf $(BIN_DIR)/build_temp

unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	$(ENABLE_CODE_COVERAGE)
	$(XCODEBUILD) $(TEST) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		$(TEST_DESTINATION) \
		$(TEST_DERIVED_DATA)


functional-test:
	@echo "######################################################################"
	@echo "### Functional Testing"
	@echo "######################################################################"
	$(ENABLE_CODE_COVERAGE)
	$(XCODEBUILD) $(TEST) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(FUNCTIONAL_TEST_SCHEME) \
		$(TEST_DESTINATION) \
		$(TEST_DERIVED_DATA)

disable-code-coverage:
	@echo "######################################################################"
	@echo "### Disabling code coverage"
	@echo "######################################################################"
	$(DISABLE_CODE_COVERAGE)

coverage:
	@echo "######################################################################"
	@echo "### Unit Test Coverage iOS"
	@echo "######################################################################"
	rm -rf $(TEST_DERIVED_DATA_PATH)/coverage
	mkdir $(TEST_DERIVED_DATA_PATH)/coverage

	# capture coverage from object files
	lcov --capture --directory \
		$(TEST_DERIVED_DATA_PATH)/Build/Intermediates.noindex/$(EXTENSION_NAME).build/Debug-iphonesimulator/$(EXTENSION_NAME).build/ \
		--output-file $(TEST_DERIVED_DATA_PATH)/coverage/test.info

	# remove non-source results
	lcov --remove $(TEST_DERIVED_DATA_PATH)/coverage/test.info '*/code/unitTests/*' '*/tools/*' '*/v1/*' '*/usr/include/*' \
		'/Applications/Xcode.app/*' '*/bourbon-core-cpp/*' '*/bourbon-ios-unit-tests/util/*' \
		-o $(TEST_DERIVED_DATA_PATH)/coverage/all.info

	# generate html report from results
	genhtml $(TEST_DERIVED_DATA_PATH)/coverage/all.info \
		--output-directory $(TEST_DERIVED_DATA_PATH)/reports/coverage


clean:
	@echo "######################################################################"
	@echo "### Cleaning..."
	@echo "######################################################################"

	-rm -rf $(BUILD_TEMP_DIR)
	-rm -rf $(BIN_DIR)$(LIBRARY_NAME)
	-rm -rf $(BIN_DIR)$(LIBRARY_NAME_SIM)
	-rm -rf $(BIN_DIR)$(LIBRARY_NAME_DEVICE)

