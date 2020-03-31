-include ./tools/makefiles/ios_common_makefile

code-format: _code-format

setup:
	(git submodule add git@git.corp.adobe.com:dms-mobile/bourbon-core-cpp-tools.git tools || true)
	(make common-setup -f ./tools/makefiles/ios_common_makefile)
	(git submodule update --init --recursive)
	(cd build/xcode && pod install)

update:
	(cd build/xcode && pod repo update && pod update)
