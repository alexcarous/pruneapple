.PHONY: setup test lint format clean build run

setup:
	git config core.hooksPath .githooks
	mise exec -- tuist generate

test:
	mise exec -- tuist test

lint:
	swiftlint lint

format:
	swiftlint --fix

clean:
	mise exec -- tuist clean

build: setup
	xcodebuild build -workspace CleanApple.xcworkspace -scheme CleanApple -configuration Release -derivedDataPath ./build
	@echo "========================================="
	@echo "✅ App compiled successfully!"
	@echo "📍 Location: ./build/Build/Products/Release/CleanApple.app"
	@echo "========================================="

run: build
	open ./build/Build/Products/Release/CleanApple.app
