.PHONY: setup test lint format clean

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
