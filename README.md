# ProgressHUD
`ProgressHUD` is a clean and easy-to-use HUD meant to display the progress of an ongoing task on macOS. 
 
[![Build Status](https://travis-ci.com/massimobio/ProgressHUD.svg?token=2EEVFqEqxnnpFcQYpwaE&branch=master)](https://travis-ci.com/massimobio/ProgressHUD)
[![macOS](https://img.shields.io/badge/platform-macOS-blue.svg)](https://www.apple.com/macos/mojave/)
[![Swift 4.2](https://img.shields.io/badge/swift-4.2-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@MassimoBi0lcati-blue.svg)](https://twitter.com/MassimoBi0lcati) 
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

Displays a simple HUD containing an optional progress indicator or cusom view and optional status message.
The ProgressHUD spans over the entire screen or in the containerView if provided.
 
![Indeterminate](hud-indeterminate.gif)

## Features

- [x] Easy to use API as extension to NSView
- [x] Sensible defaults for one line instantiation
- [x] Highly customizable theme and settings
- [x] Option to prevent user operations on components below the view
- [x] Optional completion handler called when HUD is completely hidden
- [x] Appear and Disappear notifications

## Requirements

- macOS 10.11+
- Xcode 10

## Installation

#### CocoaPods
- [ ] TODO

#### Manually
1. Download and drop  ```ProgressHUD.swift```  in your project.  
2. Congratulations!  

## Usage example

One liner:
```swift
ProgressHUD.showSuccessWithStatus("Success!")
```
Customization example:
```swift
ProgressHUD.setDefaultStyle(.custom(foreground: .yellow, backgroud: .red))
ProgressHUD.setDefaultMaskType(.black)
ProgressHUD.setDefaultPosition(.center)
```
See demo app for more examples and read documentation for the APIs in the `ProgreessHUD.swift` file.

## Contribute

We would love you for any contribution to **ProgressHUD**, check the ``LICENSE`` file for more info.
Here are some outstanding TODOs:

- [ ] Add support for Cocoapods
- [ ] Look into Mojave's dark mode
- [ ] See if it's possible to make the light and dark styles use respectively a vibrantLight and vibrantDark look
- [ ] Add the option for an animated ring for the indeterminate progress. Something like: SVProgressHUDAnimationTypeFlat, // default animation type, custom flat animation (indefinite animated ring) - This feature would need a new enum ProgressHUDAnimationType: case flat, native
- [ ] Add option to set var CGSize minimumSize
- [ ] Add option to set custom infoImage, successImage, errorImage
- [ ] Add option to set UIOffset (or the equivalent in macOS)
- [ ] Add option to set NSTimeInterval fadeInAnimationDuration, fadeOutAnimationDuration // default is 0.15
- [ ] See How SVProgressHUD handles calls on and off the main queue
- [ ] Add tests

## Meta

`ProgressHUD` was inspired by [SVProgressHUD](https://github.com/SVProgressHUD/SVProgressHUD) and [MBPROGRESSHUD-OSX](https://github.com/vanelizarov/MBProgressHUD-OSX)

Massimo Biolcati – [@MassimoBi0lcati](https://twitter.com/MassimoBi0lcati)  [@iRealProApp](https://twitter.com/iRealProApp) 

`ProgressHUD` is distributed under the terms and conditions of the [MIT license](https://github.com/massimobio/ProgressHUD/blob/master/LICENSE.md).
