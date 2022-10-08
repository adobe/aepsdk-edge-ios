
export EXTENSION_NAME = AEPEdge
export APP_NAME = TestAppSwiftUI
PROJECT_NAME = $(EXTENSION_NAME)
TARGET_NAME_XCFRAMEWORK = $(EXTENSION_NAME).xcframework
SCHEME_NAME_XCFRAMEWORK = AEPEdgeXCF

CURR_DIR := ${CURDIR}
SIMULATOR_ARCHIVE_PATH = $(CURR_DIR)/build/ios_simulator.xcarchive/Products/Library/Frameworks/
SIMULATOR_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios_simulator.xcarchive/dSYMs/
IOS_ARCHIVE_PATH = $(CURR_DIR)/build/ios.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios.xcarchive/dSYMs/

setup:
	(pod install)

setup-tools: install-githook

pod-repo-update:
	(pod repo update)

ci-pod-repo-update:
	(bundle exec pod repo update)

# pod repo update may fail if there is no repo (issue fixed in v1.8.4). Use pod install --repo-update instead
pod-install:
	(pod install --repo-update)

ci-pod-install:
	(bundle exec pod install --repo-update)

pod-update: pod-repo-update
	(pod update)

ci-pod-update: ci-pod-repo-update
	(bundle exec pod update)

open:
	open $(PROJECT_NAME).xcworkspace

clean:
	(rm -rf build)

archive: pod-update _archive

ci-archive: ci-pod-update _archive

_archive: pod-update
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES ADB_SKIP_LINT=YES
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES ADB_SKIP_LINT=YES
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(EXTENSION_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(EXTENSION_NAME).framework.dSYM -framework $(IOS_ARCHIVE_PATH)$(EXTENSION_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(EXTENSION_NAME).framework.dSYM -output ./build/$(TARGET_NAME_XCFRAMEWORK)

test:
	@echo "List of available shared Schemes in xcworkspace"
	xcodebuild -workspace $(PROJECT_NAME).xcworkspace -list
	final_scheme=""; \
	if xcodebuild -workspace $(PROJECT_NAME).xcworkspace -list | grep -q "($(PROJECT_NAME) project)"; \
	then \
	   final_scheme="$(EXTENSION_NAME) ($(PROJECT_NAME) project)" ; \
	   echo $$final_scheme ; \
	else \
	   final_scheme="$(EXTENSION_NAME)" ; \
	   echo $$final_scheme ; \
	fi; \
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme "$$final_scheme" -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES

install-githook:
	git config core.hooksPath .githooks

lint-autocorrect:
	./Pods/SwiftLint/swiftlint autocorrect

lint:
	(./Pods/SwiftLint/swiftlint lint Sources TestApps/$(APP_NAME))

check-version:
	(sh ./Script/version.sh $(VERSION))

test-SPM-integration:
	(sh ./Script/test-SPM.sh)

test-podspec:
	(sh ./Script/test-podspec.sh)
