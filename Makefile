
export EXTENSION_NAME = ACPExperiencePlatform
export OUT_DIR = out
PROJECT_NAME = $(EXTENSION_NAME)

setup: 
	(cd build/xcode && pod install)

pod-repo-update:
	(cd build/xcode && pod repo update)

pod-install: pod-repo-update
	(cd build/xcode && pod install)

pod-update: pod-repo-update
	(cd build/xcode && pod update)

open:
	open ./build/xcode/*.xcworkspace

clean:
	(rm -rf bin)
	(rm -rf ${OUT_DIR})
	(make -C build/xcode clean)
	(rm -rf build/xcode/${PROJECT_NAME}/out)

build: clean _create-out
	(set -o pipefail && make -C build/xcode build-shallow 2>&1 | tee -a ${OUT_DIR}/build.log)

build-all: clean _create-out
	(set -o pipefail && make -C build/xcode all 2>&1 | tee -a ${OUT_DIR}/build.log)

test: unit-test

unit-test: _create-out
	(mkdir -p ${OUT_DIR}/unitTest)
	(make -C build/xcode unit-test)

ci-coverage: _create-out
	(make -C build/xcode coverage)

functional-test: _create-out
	(mkdir -p ${OUT_DIR}/functionalTest)
	(make -C build/xcode functional-test)

_create-out:
	(mkdir -p ${OUT_DIR})

