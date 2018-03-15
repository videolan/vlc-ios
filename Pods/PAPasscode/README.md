# PAPasscode

PAPasscode is a standalone view controller for iOS to allow a user to set, 
enter or change a passcode. It's designed to mimic the behaviour in Settings.app
while still allowing some customization. It includes a sample project which
shows how it appears on iPhone and iPad devices.

![screen1](https://raw.github.com/dhennessy/PAPasscode/master/Screenshots/screen1.png)
![screen2](https://raw.github.com/dhennessy/PAPasscode/master/Screenshots/screen2.png)

Other features:
 *	Supports both simple (PIN-style) and regular passcodes
 *	Allows customization of title and prompts
 *  Animates screens left and right
 *	Requires ARC

## Adding PAPasscode to your project

The simplest way to add PAPasscode to your project is to use [CocoaPods](http://cocoapods.org). 
Simply add the following line to your Podfile:

```
	pod 'PAPasscode'
```

If you'd prefer to manually integrate it, simply copy `PAPasscode/*.{m,h}` and `Assets/*.png` 
into your project.  Make sure you link with the QuartzCore framework.

## Asking the user to set a passcode

First, implement the following delegate methods on your view controller:

```objective-c
- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller {
	// Do stuff with controller.passcode...
    [self dismissViewControllerAnimated:YES completion:nil];
}
```

Then invoke the view controller as follows:

```objective-c
    PAPasscodeViewController *passcodeViewController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
    passcodeViewController.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:passcodeViewController] animated:YES completion:nil];
```

The `initForAction:` allows you to specify the flow you'd like. Possible actions are:
 *   `PasscodeActionSet` - set a new passcode
 *   `PasscodeActionEnter` - enter an existing passcode
 *   `PasscodeActionChange` - change an existing passcode

The included example project demonstrates the each of the flows.

## Changelog

### 1.0
 *  Update to support auto-layout and change UI to match iOS 7 styling. Note that if you require support for iOS 6, you should stick with version 0.3.
 
### 0.3
 *  The `PAPasscodeViewControllerDidCancel:` delegate method is now optional. If missing, then the Cancel button will be removed.

### 0.2
 *  Add property to specify custom background view

### 0.1 
 *  Initial release

## Contact

To hear about updates to this and other libraries follow me on Twitter ([@denishennessy](http://twitter.com/denishennessy)) or App.net ([@denishennessy](http://alpha.app.net/denishennessy)).

If you encounter a bug or just thought of a terrific new feature, then opening a github issue is probably the best
way to share it. Actually, the best way is to send me a pull request...

For anything else, email always works: [denis@peerassembly.com](mailto:denis@peerassembly.com)

## License

```
Copyright (c) 2012-2015, Denis Hennessy (Peer Assembly - http://peerassembly.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Peer Assembly, Denis Hennessy nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PEER ASSEMBLY OR DENIS HENNESSY BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

