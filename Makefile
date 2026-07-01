.PHONY: setup test lint format clean build run release

setup:
	git config core.hooksPath .githooks
	mise exec -- tuist install
	mise exec -- tuist generate

test:
	mise exec -- tuist test --skip-ui-tests

lint:
	swiftlint lint

format:
	swiftlint --fix

clean:
	mise exec -- tuist clean

build: setup
	xcodebuild build -workspace Pruneapple.xcworkspace -scheme Pruneapple -configuration Release -derivedDataPath ./build
	@echo "========================================="
	@echo "✅ App compiled successfully!"
	@echo "📍 Location: ./build/Build/Products/Release/Pruneapple.app"
	@echo "========================================="

run: build
	open ./build/Build/Products/Release/Pruneapple.app

release: build
	@echo "Checking if create-dmg is installed..."
	@which create-dmg > /dev/null || (echo "❌ Error: 'create-dmg' is not installed. Run 'brew install create-dmg' first." && exit 1)
	@echo "Setting up packaging directory..."
	rm -rf build/Build/Products/Release/dmg_source
	mkdir -p build/Build/Products/Release/dmg_source
	@echo "Copying app and stripping local metadata..."
	cp -R build/Build/Products/Release/Pruneapple.app build/Build/Products/Release/dmg_source/
	xattr -cr build/Build/Products/Release/dmg_source/Pruneapple.app
	@echo "Generating styled DMG..."
	rm -f build/Build/Products/Release/Pruneapple.dmg
	create-dmg \
	  --volname "Pruneapple Installer" \
	  --window-pos 200 120 \
	  --window-size 600 400 \
	  --icon-size 100 \
	  --icon "Pruneapple.app" 175 120 \
	  --app-drop-link 425 120 \
	  "build/Build/Products/Release/Pruneapple.dmg" \
	  "build/Build/Products/Release/dmg_source/"
	@echo "Cleaning up packaging directory..."
	rm -rf build/Build/Products/Release/dmg_source
	@echo "Reading version from Info.plist..."
	$(eval VERSION := $(shell defaults read $(PWD)/build/Build/Products/Release/Pruneapple.app/Contents/Info.plist CFBundleShortVersionString))
	@echo "Generating appcast.xml for version $(VERSION)..."
	./Tuist/.build/artifacts/sparkle/Sparkle/bin/generate_appcast \
		--download-url-prefix "https://github.com/alexcarous/pruneapple/releases/download/v$(VERSION)/" \
		-o build/Build/Products/Release/appcast.xml \
		build/Build/Products/Release/
	@echo "========================================="
	@echo "✅ Release assets generated successfully!"
	@echo "📍 DMG: ./build/Build/Products/Release/Pruneapple.dmg"
	@echo "📍 Appcast: ./build/Build/Products/Release/appcast.xml"
	@echo "========================================="

