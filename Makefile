.PHONY: test-framework
test-framework:
	swift test


ExampleTargets := "CounterExampleTests" "TodoExampleTests" "PagingListExampleTests"

.PHONY: test-examples
test-examples:
	cd ./Example && $(foreach target,$(ExampleTargets),xcodebuild test -scheme $(target) -destination platform="iOS Simulator,name=iPhone 14 Pro";)

test-all: test-framework test-examples
