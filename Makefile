.PHONY: setup test lint format clean build run

setup:
	git config core.hooksPath .githooks
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
