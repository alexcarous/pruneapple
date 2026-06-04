.PHONY: setup test lint format clean

setup:
	mise exec -- tuist generate

test:
	mise exec -- tuist test

lint:
	swiftlint lint

format:
	swiftlint --fix

clean:
	mise exec -- tuist clean
