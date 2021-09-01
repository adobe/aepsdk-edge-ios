
export EXTENSION_NAME = AEPEdge
export APP_NAME = AEPCommerceDemoApp
PROJECT_NAME = $(EXTENSION_NAME)
TARGET_NAME_XCFRAMEWORK = $(EXTENSION_NAME).xcframework
SCHEME_NAME_XCFRAMEWORK = AEPEdgeXCF

SIMULATOR_ARCHIVE_PATH = ./build/ios_simulator.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_PATH = ./build/ios.xcarchive/Products/Library/Frameworks/

setup:
	(pod install)
	(cd SampleApps/$(APP_NAME) && pod install)

setup-tools: install-swiftlint install-githook

pod-repo-update:
	(pod repo update)
	(cd SampleApps/$(APP_NAME) && pod repo update)

ci-pod-repo-update:
	(bundle exec pod repo update)
	(cd SampleApps/$(APP_NAME) && bundle exec pod repo update)

# pod repo update may fail if there is no repo (issue fixed in v1.8.4). Use pod install --repo-update instead
pod-install:
	(pod install --repo-update)
	(cd SampleApps/$(APP_NAME) && pod install --repo-update)

ci-pod-install:
	(bundle exec pod install --repo-update)
	(cd SampleApps/$(APP_NAME) && bundle exec pod install --repo-update)

pod-update: pod-repo-update
	(pod update)
	(cd SampleApps/$(APP_NAME) && pod update)

ci-pod-update: ci-pod-repo-update
	(bundle exec pod update)
	(cd SampleApps/$(APP_NAME) && bundle exec pod update)

open:
	open $(PROJECT_NAME).xcworkspace

open-app:
	open ./SampleApps/$(APP_NAME)/*.xcworkspace

clean:
	(rm -rf build)

build-app:
	make -C SampleApps/$(APP_NAME) build-shallow

archive: pod-update _archive

ci-archive: ci-pod-update _archive

_archive:
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES ADB_SKIP_LINT=YES
	xcodebuild archive -workspace $(PROJECT_NAME).xcworkspace -scheme $(SCHEME_NAME_XCFRAMEWORK) -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES ADB_SKIP_LINT=YES
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(EXTENSION_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(EXTENSION_NAME).framework -output ./build/$(TARGET_NAME_XCFRAMEWORK)

test:
	@echo "######################################################################"
	@echo "### Testing iOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(PROJECT_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES ADB_SKIP_LINT=YES


install-swiftlint:
	HOMEBREW_NO_AUTO_UPDATE=1 brew install swiftlint && brew cleanup swiftlint

install-githook:
	git config core.hooksPath .githooks

lint-autocorrect:
	(swiftlint --fix --format)

lint:
	(swiftlint lint Sources SampleApps/AEPCommerceDemoApp)

check-version:
	(sh ./Script/version.sh $(VERSION))

test-SPM-integration:
	(sh ./Script/test-SPM.sh)

test-podspec:
	(sh ./Script/test-podspec.sh)
