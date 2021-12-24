
# React Native Sodyo SDK Plugin that wraps Sodyo sdk for Android and iOS

[SodyoSDK for iOS](https://github.com/sodyo-ltd/SodyoSDKPod) v3.54.28

[SodyoSDK for Android](https://search.maven.org/search?q=a:sodyo-android-sdk) v3.54.35


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

Use scanner as fragment (only after initialize SodyoSDK)
```
import { Scanner } from '@sodyo/react-native-sodyo-sdk'
...
<Scanner isEnabled={true}>
    <Text>Children on top of the scanner</Text>
</Scanner>
```
`isEnabled toggles the Scanners active / pause status.`

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

Close Sodyo scanner (if scanner run by SodyoSDK.start())
```
SodyoSDK.close()
```

Marker content listener
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

Remove all listeners
```
SodyoSDK.removeAllListeners()
```

If you get an error similar to this when building Android:
```
More than one file was found with OS independent path 'META-INF/DEPENDENCIES'
```

then add in your `android/app/build.gradle` file add the following:
```
android {
    ...

    packagingOptions {
        ...

        exclude "META-INF/DEPENDENCIES.txt"
        exclude "META-INF/LICENSE.txt"
        exclude "META-INF/NOTICE.txt"
        exclude "META-INF/NOTICE"
        exclude "META-INF/LICENSE"
        exclude "META-INF/DEPENDENCIES"
        exclude "META-INF/notice.txt"
        exclude "META-INF/license.txt"
        exclude "META-INF/dependencies.txt"
        exclude "META-INF/LGPL2.1"
        exclude "META-INF/ASL2.0"
        exclude "META-INF/maven/com.google.guava/guava/pom.properties"
        exclude "META-INF/maven/com.google.guava/guava/pom.xml"
    }
}
```


For more examples see [the sample app](https://github.com/sodyo-ltd/react-native-sample-app)
