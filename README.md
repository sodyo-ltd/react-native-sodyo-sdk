
# React Native Sodyo SDK Plugin that wraps Sodyo sdk for Android and iOS

[SodyoSDK for iOS](https://github.com/sodyo-ltd/SodyoSDKPod) v 3.51.15

[SodyoSDK for Android](https://search.maven.org/search?q=a:sodyo-android-sdk) v 3.51.15


## Install
    npm i @sodyo/react-native-sodyo-sdk -E

If you using version of react-native < 60 then you have to make a link

    react-native link
    
[Requires multidex support for android](https://medium.com/@aungmt/multidex-on-androidx-for-rn-0-60-x-cbb37c50d85)

## Quick start
Init the plugin with your Sodyo App Key project token with
```
import SodyoSdk from '@sodyo/react-native-sodyo-sdk'

SodyoSDK.init(your-app-key,
    function(){ /* successful init callback */ },
    function(){ /* fail init callback */})
```

Set the Sodyo error listener
```
SodyoSDK.onError(
    function(err){ /* fail callback */ }
)
```
`For unsubscribing just call the returned function`

Open the Sodyo scanner
```
SodyoSDK.start(
    function(markerData){ /* data content callback */ },
    function(err){ /* fail */}
)
```

Close Sodyo scanner
```
SodyoSDK.close()
```

Marker listener
```
SodyoSDK.onMarkerContent(
    function(markerId, markerData){ /* successfully scanned marker */ },
)
```
`For unsubscribing just call the returned function`

Load marker by Id
```
SodyoSDK.performMarker(markerId)
```

Personal User Information (some object)

```
SodyoSDK.setUserInfo(userInfo)
```


User Identification (ID)
```
SodyoSDK.setAppUserId(userId)
```

Setting Scanner Preferences (some flat object)
```
SodyoSDK.setScannerParams(scannerPreferences)
```

Personalized Content
```
SodyoSDK.setCustomAdLabel(label)
```
`The label may include one or more tags in comma-separated values (CSV) format as follows: “label1,label2,label3”`

Customizing the scanner user interface
```
// set any html (with css)
SodyoSDK.setOverlayView('<a href="sodyosdk://handleClose">Close</a>') 

// define a handler for the button
SodyoSDK.setOverlayCallback('handleClose', () => { /* do something */ });
```

Remove all listeners (including overlay callbacks)
```
SodyoSDK.removeAllListeners()
```

For more examples see [the sample app](https://github.com/sodyo-ltd/react-native-sample-app)
