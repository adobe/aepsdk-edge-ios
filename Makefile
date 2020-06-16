
export EXTENSION_NAME = ACPExperiencePlatform
export OUT_DIR = out
PROJECT_NAME = $(EXTENSION_NAME)

setup:
	(cd build/xcode && pod install)
	(cd demo/AEPCommerceDemoApp && pod install)

update:
	pod repo update
	(cd build/xcode && pod update)
	(cd demo/AEPCommerceDemoApp && pod update)

open:
	open ./build/xcode/*.xcworkspace

open-app:
	open ./demo/AEPCommerceDemoApp/*.xcworkspace

clean:
	(rm -rf bin)
	(rm -rf ${OUT_DIR})
	(make -C build/xcode clean)
	(rm -rf build/xcode/${PROJECT_NAME}/out)

build: clean _create-out
	(set -o pipefail && make -C build/xcode build-shallow 2>&1 | tee -a ${OUT_DIR}/build.log)

build-all: clean _create-out
	(set -o pipefail && make -C build/xcode all 2>&1 | tee -a ${OUT_DIR}/build.log)

build-app: _create-out
	(set -o pipefail && make -C demo/AEPCommerceDemoApp build-shallow 2>&1 | tee -a $(OUT_DIR)/appbuild.log)

archive-app: _create-out
	(make -C demo/AEPCommerceDemoApp archive-app)

test: unit-test

unit-test: _create-out
	(mkdir -p ${OUT_DIR}/unitTest)
	(make -C build/xcode unit-test)

functional-test: _create-out
	(mkdir -p ${OUT_DIR}/functionalTest)
	(make -C build/xcode functional-test)

_create-out:
	(mkdir -p ${OUT_DIR})

