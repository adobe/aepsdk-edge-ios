
export EXTENSION_NAME = AEPExperiencePlatform
export APP_NAME = AEPCommerceDemoApp
export OUT_DIR = out
PROJECT_NAME = $(EXTENSION_NAME)

setup: 
	(cd build/xcode && pod install)
	(cd demo/$(APP_NAME) && pod install)

setup-tools: install-swiftlint install-githook

pod-repo-update:
	(cd build/xcode && pod repo update)
	(cd demo/$(APP_NAME) && pod repo update)

# pod repo update may fail if there is no repo (issue fixed in v1.8.4). Use pod install --repo-update instead
pod-install:
	(cd build/xcode && pod install --repo-update)
	(cd demo/$(APP_NAME) && pod install --repo-update)

pod-update: pod-repo-update
	(cd build/xcode && pod update)
	(cd demo/$(APP_NAME) && pod update)

open:
	open ./build/xcode/*.xcworkspace

open-app:
	open ./demo/$(APP_NAME)/*.xcworkspace

clean:
	(rm -rf bin)
	(rm -rf $(OUT_DIR))
	(make -C build/xcode clean)
	(rm -rf build/xcode/$(PROJECT_NAME)/out)

build: clean _create-out
	(set -o pipefail && make -C build/xcode build-shallow 2>&1 | tee -a $(OUT_DIR)/build.log)

build-all: clean _create-out
	(set -o pipefail && make -C build/xcode all 2>&1 | tee -a $(OUT_DIR)/build.log)

build-app: _create-out
	(set -o pipefail && make -C demo/$(APP_NAME) build-shallow 2>&1 | tee -a $(OUT_DIR)/appbuild.log)

archive-app: _create-out
	(make -C demo/$(APP_NAME) archive-app)

test: unit-test

unit-test: _create-out
	(mkdir -p $(OUT_DIR)/unitTest)
	(make -C build/xcode unit-test)

functional-test: _create-out
	(mkdir -p $(OUT_DIR)/functionalTest)
	(make -C build/xcode functional-test)

install-swiftlint:
	HOMEBREW_NO_AUTO_UPDATE=1 brew install swiftlint && brew cleanup swiftlint

install-githook:
	./tools/git-hooks/setup.sh

autocorrect-format:
	(swiftlint autocorrect --format)

lint-format:
	(swiftlint lint code/src demo/AEPCommerceDemoApp)

_create-out:
	(mkdir -p $(OUT_DIR))


	




