setup:
	(cd build/xcode && pod install)

update:
	(cd build/xcode && pod repo update && pod update)
