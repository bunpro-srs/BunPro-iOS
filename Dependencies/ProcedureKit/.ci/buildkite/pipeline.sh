#!/bin/bash
cat <<-YAML
steps:
-
  name: "Stress Test"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane mac stress_test"
  agents:
    queue: "stress-tests"
    xcode: "$XCODE"    
-
  name: "ProcedureKit"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane mac test"
  agents:
    xcode: "$XCODE"
-
  name: "Cloud"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane mac test_cloud"
  agents:
    xcode: "$XCODE"
-
  name: "CoreData"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane mac test_coredata"
  agents:
    xcode: "$XCODE"   
-
  name: "Location"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane mac test_location"
  agents:
    xcode: "$XCODE"      
-
  name: "Network"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane mac test_network"
  agents:
    xcode: "$XCODE"            
-
  name: "Mac"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane mac test_mac"
  agents:
    xcode: "$XCODE"      
-
  name: "ProcedureKit (iOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_ios"
  agents:
    queue: "iOS-Simulator"
    xcode: "$XCODE"
-
  name: "Cloud (iOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_cloud_ios"
  agents:
    queue: "iOS-Simulator" 
    xcode: "$XCODE"      
-
  name: "CoreData (iOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_coredata_ios"
  agents:
    queue: "iOS-Simulator" 
    xcode: "$XCODE"
-
  name: "Location (iOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_location_ios"
  agents:
    queue: "iOS-Simulator"
    xcode: "$XCODE"    
-
  name: "Network (iOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_network_ios"
  agents:
    queue: "iOS-Simulator"
    xcode: "$XCODE"
-
  name: "Mobile (iOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_mobile_ios"
  agents:
    queue: "iOS-Simulator" 
    xcode: "$XCODE"      
-
  name: "ProcedureKit (tvOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_tvos"
  agents:
    queue: "iOS-Simulator"
    xcode: "$XCODE"
-
  name: "Cloud (tvOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_cloud_tvos"
  agents:
    queue: "iOS-Simulator" 
    xcode: "$XCODE"
-
  name: "CoreData (tvOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_cloud_tvos"
  agents:
    queue: "iOS-Simulator" 
    xcode: "$XCODE"
-
  name: "Location (tvOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_location_tvos"
  agents:
    queue: "iOS-Simulator" 
    xcode: "$XCODE"
-
  name: "Network (tvOS)"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_network_tvos"
  agents:
    queue: "iOS-Simulator" 
    xcode: "$XCODE"
-
  name: "TV"
  command: "source /usr/local/opt/chruby/share/chruby/chruby.sh && chruby ruby && bundle install --quiet && bundle exec fastlane ios test_tv_tvos"
  agents:
    queue: "iOS-Simulator"
    xcode: "$XCODE"
YAML

if [[ "$BUILDKITE_BUILD_CREATOR" == "Daniel Thorpe" ]]; then
cat <<-YAML

- wait

- 
  name: "Test CocoaPods Integration"
  trigger: "tryprocedurekit"
  build:
    message: "Testing ProcedureKit Integration via Cocoapods"
    commit: "HEAD"
    branch: "cocoapods"
    env:
      PROCEDUREKIT_HASH: "$COMMIT"
YAML
fi

cat <<-YAML

- wait

YAML

if [[ "$BUILDKITE_BUILD_CREATOR" != "Daniel Thorpe" ]]; then
cat <<-YAML

- block: "Docs"

YAML
fi

cat <<-YAML

- 
  name: ":aws: Generate Docs"
  trigger: "procedurekit-documentation"
  build:
    message: "Generating documentation for ProcedureKit"
    commit: "HEAD"
    branch: "master"
    env:
      PROCEDUREKIT_HASH: "$COMMIT"
      PROCEDUREKIT_BRANCH: "$BRANCH"
YAML