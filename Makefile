
export EXTENSION_NAME = ACPExperiencePlatform
PROJECT_NAME = $(EXTENSION_NAME)

setup:
	(git submodule update --init --recursive)
	#(make common-setup -f ./tools/makefiles/ios_common_makefile)
	(cd build/xcode && pod install)

update:
	(cd build/xcode && pod repo update && pod update)
	(git submodule update --remote)

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

code-format: _code-format

check-format: _check-format

unit-test: _create-out
	(mkdir -p out/unitTest)
	(make -C build/xcode unit-test)
	(mv build/xcode/${PROJECT_NAME}/out/Build/reports out/unitTest)

ci-coverage: _create-out
	(make -C build/xcode coverage)
	(mv build/xcode/${PROJECT_NAME}/out/reports/* out/unitTest)

functional-test: _create-out
	(mkdir -p out/functionalTest)
	(make -C build/xcode functional-test)
	(mv build/xcode/${PROJECT_NAME}/out/Build/reports/FunctionalTests/* out/functionalTest/)

_create-out:
	(mkdir -p out)

_code-format:
	(echo)

_check-format:
	(echo)

