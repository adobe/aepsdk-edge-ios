export EXTENSION_NAME = AEPEdge
PROJECT_NAME = $(EXTENSION_NAME)
SCHEME_NAME_XCFRAMEWORK = AEPEdgeXCF
TEST_APP_IOS_SCHEME = TestAppiOS
TEST_APP_TVOS_SCHEME = TestApptvOS

CURR_DIR := ${CURDIR}
IOS_SIMULATOR_ARCHIVE_PATH = $(CURR_DIR)/build/ios_simulator.xcarchive/Products/Library/Frameworks/
IOS_SIMULATOR_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios_simulator.xcarchive/dSYMs/
IOS_ARCHIVE_PATH = $(CURR_DIR)/build/ios.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios.xcarchive/dSYMs/
TVOS_SIMULATOR_ARCHIVE_PATH = $(CURR_DIR)/build/tvos_simulator.xcarchive/Products/Library/Frameworks/
TVOS_SIMULATOR_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/tvos_simulator.xcarchive/dSYMs/
TVOS_ARCHIVE_PATH = $(CURR_DIR)/build/tvos.xcarchive/Products/Library/Frameworks/
TVOS_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/tvos.xcarchive/dSYMs/

# Values with defaults
IOS_DEVICE_NAME ?= iPhone 15
# If OS version is not specified, uses the first device name match in the list of available simulators
IOS_VERSION ?= 
ifeq ($(strip $(IOS_VERSION)),)
    IOS_DESTINATION = "platform=iOS Simulator,name=$(IOS_DEVICE_NAME)"
else
    IOS_DESTINATION = "platform=iOS Simulator,name=$(IOS_DEVICE_NAME),OS=$(IOS_VERSION)"
endif

TVOS_DEVICE_NAME ?= Apple TV
# If OS version is not specified, uses the first device name match in the list of available simulators
TVOS_VERSION ?=
ifeq ($(strip $(TVOS_VERSION)),)
	TVOS_DESTINATION = "platform=tvOS Simulator,name=$(TVOS_DEVICE_NAME)"
else
	TVOS_DESTINATION = "platform=tvOS Simulator,name=$(TVOS_DEVICE_NAME),OS=$(TVOS_VERSION)"
endif

clean-derived-data:
	@if [ -z "$(SCHEME)" ]; then \
		echo "Error: SCHEME variable is not set."; \
		exit 1; \
	fi; \
	if [ -z "$(DESTINATION)" ]; then \
		echo "Error: DESTINATION variable is not set."; \
		exit 1; \
	fi; \
	echo "Cleaning derived data for scheme: $(SCHEME) with destination: $(DESTINATION)"; \
	DERIVED_DATA_PATH=`xcodebuild -workspace $(PROJECT_NAME).xcworkspace -scheme "$(SCHEME)" -destination "$(DESTINATION)" -showBuildSettings | grep -m1 'BUILD_DIR' | awk '{print $$3}' | sed 's|/Build/Products||'`; \
	echo "DerivedData Path: $$DERIVED_DATA_PATH"; \
	\
	LOGS_TEST_DIR=$$DERIVED_DATA_PATH/Logs/Test; \
	echo "Logs Test Path: $$LOGS_TEST_DIR"; \
	\
	if [ -d "$$LOGS_TEST_DIR" ]; then \
		echo "Removing existing .xcresult files in $$LOGS_TEST_DIR"; \
		rm -rf "$$LOGS_TEST_DIR"/*.xcresult; \
	else \
		echo "Logs/Test directory does not exist. Skipping cleanup."; \
	fi;

setup-tools: install-githook

setup:
	pod install

clean:
	rm -rf build

pod-install:
	pod install --repo-update

open:
	open $(PROJECT_NAME).xcworkspace

pod-repo-update:
	pod repo update

pod-update: pod-repo-update
	pod update

ci-pod-repo-update:
	bundle exec pod repo update

ci-pod-install:
	bundle exec pod install --repo-update

ci-pod-update: ci-pod-repo-update
	bundle exec pod update

ci-archive: ci-pod-install _archive

archive: pod-install _archive

_archive: clean build-ios build-tvos
	@echo "######################################################################"
	@echo "### Generating iOS and tvOS Frameworks for $(PROJECT_NAME)"
	@echo "######################################################################"
	xcodebuild -create-xcframework -framework $(IOS_SIMULATOR_ARCHIVE_PATH)$(PROJECT_NAME).framework -debug-symbols $(IOS_SIMULATOR_ARCHIVE_DSYM_PATH)$(PROJECT_NAME).framework.dSYM \
	-framework $(TVOS_SIMULATOR_ARCHIVE_PATH)$(PROJECT_NAME).framework -debug-symbols $(TVOS_SIMULATOR_ARCHIVE_DSYM_PATH)$(PROJECT_NAME).framework.dSYM \
	-framework $(IOS_ARCHIVE_PATH)$(PROJECT_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(PROJECT_NAME).framework.dSYM \
	-framework $(TVOS_ARCHIVE_PATH)$(PROJECT_NAME).framework -debug-symbols $(TVOS_ARCHIVE_DSYM_PATH)$(PROJECT_NAME).framework.dSYM -output ./build/$(PROJECT_NAME).xcframework
	
build-ios:
	@echo "######################################################################"
	@echo "### Building iOS archive"
	@echo "######################################################################"
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES ADB_SKIP_LINT=YES
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES ADB_SKIP_LINT=YES

build-tvos:
	@echo "######################################################################"
	@echo "### Building tvOS archive"
	@echo "######################################################################"
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/tvos.xcarchive" -sdk appletvos -destination="tvOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES ADB_SKIP_LINT=YES
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/tvos_simulator.xcarchive" -sdk appletvsimulator -destination="tvOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES ADB_SKIP_LINT=YES

zip:
	cd build && zip -r -X $(PROJECT_NAME).xcframework.zip $(PROJECT_NAME).xcframework/
	swift package compute-checksum build/$(PROJECT_NAME).xcframework.zip

build-app: setup
	@echo "######################################################################"
	@echo "### Building $(TEST_APP_IOS_SCHEME)"
	@echo "######################################################################"
	xcodebuild clean build -workspace $(PROJECT_NAME).xcworkspace -scheme $(TEST_APP_IOS_SCHEME) -destination 'generic/platform=iOS Simulator'

	@echo "######################################################################"
	@echo "### Building $(TEST_APP_TVOS_SCHEME)"
	@echo "######################################################################"
	xcodebuild clean build -workspace $(PROJECT_NAME).xcworkspace -scheme $(TEST_APP_TVOS_SCHEME) -destination 'generic/platform=tvOS Simulator'

test: unit-test-ios functional-test-ios unit-test-tvos functional-test-tvos

unit-test-ios:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	@$(MAKE) clean-derived-data SCHEME=UnitTests DESTINATION=$(IOS_DESTINATION)
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme "UnitTests" -destination $(IOS_DESTINATION) -enableCodeCoverage YES ADB_SKIP_LINT=YES

functional-test-ios:
	@echo "######################################################################"
	@echo "### Functional Testing iOS"
	@echo "######################################################################"
	@$(MAKE) clean-derived-data SCHEME=FunctionalTests DESTINATION=$(IOS_DESTINATION)
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme "FunctionalTests" -destination $(IOS_DESTINATION) -enableCodeCoverage YES ADB_SKIP_LINT=YES

unit-test-tvos:
	@echo "######################################################################"
	@echo "### Unit Testing tvOS"
	@echo "######################################################################"
	@$(MAKE) clean-derived-data SCHEME=UnitTests DESTINATION=$(TVOS_DESTINATION)
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme "UnitTests" -destination $(TVOS_DESTINATION) -enableCodeCoverage YES ADB_SKIP_LINT=YES

functional-test-tvos:
	@echo "######################################################################"
	@echo "### Functional Testing tvOS"
	@echo "######################################################################"
	@$(MAKE) clean-derived-data SCHEME=FunctionalTests DESTINATION=$(TVOS_DESTINATION)
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme "FunctionalTests" -destination $(TVOS_DESTINATION) -enableCodeCoverage YES ADB_SKIP_LINT=YES

integration-test-ios: upstream-integration-test-ios

# Runs the Edge Network (Konductor) integration tests after installing pod dependencies
# Usage: 
# make upstream-integration-test-ios MOBILE_PROPERTY_ID=<property_id> EDGE_LOCATION_HINT=<location_hint>
# If MOBILE_PROPERTY_ID is not specified, test target will use its default value.
.SILENT: upstream-integration-test-ios # Silences Makefile's automatic echo of commands
upstream-integration-test-ios: pod-install; \
	$(MAKE) clean-derived-data SCHEME=UpstreamIntegrationTests DESTINATION=$(IOS_DESTINATION)
	if [ -z "$$EDGE_ENVIRONMENT" ]; then \
		echo ''; \
		echo '-------------------------- WARNING -------------------------------'; \
		echo 'EDGE_ENVIRONMENT was NOT set; the test will use its default value.'; \
		echo '------------------------------------------------------------------'; \
		echo ''; \
	fi; \
	xcodebuild test \
	-workspace $(PROJECT_NAME).xcworkspace \
	-scheme UpstreamIntegrationTests \
	-destination $(IOS_DESTINATION) \
	-enableCodeCoverage YES \
	ADB_SKIP_LINT=YES \
	TAGS_MOBILE_PROPERTY_ID=$(TAGS_MOBILE_PROPERTY_ID) \
	EDGE_LOCATION_HINT=$(EDGE_LOCATION_HINT)

install-githook:
	git config core.hooksPath .githooks

lint-autocorrect:
	./Pods/SwiftLint/swiftlint --fix

lint:
	./Pods/SwiftLint/swiftlint lint Sources TestApps

test-SPM-integration:
	sh ./Script/test-SPM.sh

test-podspec:
	sh ./Script/test-podspec.sh