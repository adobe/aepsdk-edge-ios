-include ./tools/makefiles/ios_common_makefile

code-format: _code-format

setup:
	(git submodule update --init --recursive)
	(make common-setup -f ./tools/makefiles/ios_common_makefile)
	(cd build/xcode && pod install)

update:
	(cd build/xcode && pod repo update && pod update)
