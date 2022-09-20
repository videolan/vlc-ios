fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
### release
```
fastlane release
```
Release a new version of VLC to the App Store



This action requires the following parameters:

- platform (iOS or tvOS)



This action does the following:

- Ensure a clean git status

- Clear derived data

- Set the version, bump the build number and commit the change

- Apply the privateConstants which include the credentials

- Install cocoapods dependencies

- Build and sign the app

- Update the changelog from the NEWS file

- Push the version bump
### lint
```
fastlane lint
```
Check style and conventions
### ci
```
fastlane ci
```

### screenshots
```
fastlane screenshots
```
Take screenshots
### test
```
fastlane test
```
Run Tests

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
