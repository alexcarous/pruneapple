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
	@echo "Zipping app (preserving symlinks)..."
	cd build/Build/Products/Release/ && rm -f Pruneapple.zip && zip -ry Pruneapple.zip Pruneapple.app
	@echo "Reading version from Info.plist..."
	$(eval VERSION := $(shell defaults read $(PWD)/build/Build/Products/Release/Pruneapple.app/Contents/Info.plist CFBundleShortVersionString))
	@echo "Generating appcast.xml for version $(VERSION)..."
	./Tuist/.build/artifacts/sparkle/Sparkle/bin/generate_appcast \
		--download-url-prefix "https://github.com/alexcarous/pruneapple/releases/download/v$(VERSION)/" \
		-o build/Build/Products/Release/appcast.xml \
		build/Build/Products/Release/
	@echo "========================================="
	@echo "✅ Release assets generated successfully!"
	@echo "📍 Zip: ./build/Build/Products/Release/Pruneapple.zip"
	@echo "📍 Appcast: ./build/Build/Products/Release/appcast.xml"
	@echo "========================================="

