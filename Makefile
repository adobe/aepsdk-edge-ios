-include ./tools/makefiles/ios_common_makefile

export EXTENSION_NAME = ACPExperiencePlatform
PROJECT_NAME = $(EXTENSION_NAME)

setup:
	(git submodule update --init --recursive)
	(make common-setup -f ./tools/makefiles/ios_common_makefile)
	(cd build/xcode && pod install)

update:
	(cd build/xcode && pod repo update && pod update)
	(git submodule update --remote)

code-format: _code-format

ci-setup: _project-verification
	(cd build/xcode && pod repo update || true && pod install)
	#(make common-setup -f ./tools/makefiles/ios_common_makefile)

ci-check-format: _check-format

ci-clean: _clean
	(make -C build/xcode clean)
	(rm -rf build/xcode/${PROJECT_NAME}/out)

ci-build: ci-clean _create-ci
	(set -o pipefail && make -C build/xcode build-shallow 2>&1 | tee -a ci/build.log)

ci-build-all: ci-clean _create-ci
	(set -o pipefail && make -C build/xcode all 2>&1 | tee -a ci/build.log)


ci-unit-test: _create-ci
	(mkdir -p ci/unitTest)
	(make -C build/xcode unit-test)
	(mv build/xcode/${PROJECT_NAME}/out/Build/reports ci/unitTest)

ci-coverage: _create-ci
	(make -C build/xcode coverage)
	(mv build/xcode/${PROJECT_NAME}/out/reports/* ci/unitTest)

ci-functional-test: _create-ci
	(mkdir -p ci/functionalTest)
	(make -C build/xcode functional-test)
	(mv build/xcode/${PROJECT_NAME}/out/Build/reports/FunctionalTests/* ci/functionalTest/)