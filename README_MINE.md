# Running the app issues I had . 

In `.vscode/`, create a `settings.json` folder as below in order to specify Flutter 2.10.5 (instead of the Flutter 3.0.2 you have globally instead). 
- Either way, I ran the flutter 2.10.5 binary directly as below: 

```
/path/to/flutter2.10.5sdk/flutter clean
/path/to/flutter2.10.5sdk/flutter run -d chrome
```

Then, it was hanging somewhere on startup, displaying a blank screen only, sees like it was due to `authentication_repository.dart`. 
I commented out the line below to skip signing in to firebase - 

``` 
// await _firebaseAuth.signInAnonymously();
```

At this stage, it ran fine on chrome!
--------------------------

## Running on Ios

Continuing on from above, I had to update `ios/Podfile`, uncommenting line 2 and replacing with `platform :ios, '10.0'`. 
Then, set simulator in VS Code to `iPhone SE (3rd generation) (ios simulator)` and ran it. 
 
Next, because I am running on a Mac Studio (M1 Max Chip), I had to use the following command to get past some error during CocoaPods install:
```
arch -x86_64 flutter run
```


