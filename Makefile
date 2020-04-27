
export EXTENSION_NAME = ACPExperiencePlatform
PROJECT_NAME = $(EXTENSION_NAME)

setup:
	(cd build/xcode && pod install)

update:
	(cd build/xcode && pod repo update && pod update)

open:
	open ./build/xcode/*.xcworkspace

clean:
	(rm -rf bin)
	(rm -rf out)
	(make -C build/xcode clean)
	(rm -rf build/xcode/${PROJECT_NAME}/out)

build: clean _create-out
	(set -o pipefail && make -C build/xcode build-shallow 2>&1 | tee -a out/build.log)

build-all: clean _create-out
	(set -o pipefail && make -C build/xcode all 2>&1 | tee -a out/build.log)

test: unit-test

unit-test: _create-out
	(mkdir -p out/unitTest)
	(make -C build/xcode unit-test)

ci-coverage: _create-out
	(make -C build/xcode coverage)

functional-test: _create-out
	(mkdir -p out/functionalTest)
	(make -C build/xcode functional-test)

_create-out:
	(mkdir -p out)

