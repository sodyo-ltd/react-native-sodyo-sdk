import React, { Component, Fragment } from 'react';
import {
  View,
  requireNativeComponent,
  NativeModules,
  NativeEventEmitter,
  Platform,
  StyleSheet,
} from 'react-native';

const { RNSodyoSdk } = NativeModules;

const eventEmitter = new NativeEventEmitter(RNSodyoSdk);

export default {
  init: (apiKey, successCallback, errorCallback) => {
    return RNSodyoSdk.init(apiKey, successCallback, errorCallback);
  },

  onError: (callback) => {
    eventEmitter.removeAllListeners('EventSodyoError');

    const subscription = eventEmitter.addListener('EventSodyoError', (e) => {
      if (typeof callback === 'function') {
        callback(e.error);
      }
    });

    return () => {
      return subscription.remove();
    };
  },

  onCloseScanner: (callback) => {
    if (Platform.OS === 'ios') {
      return () => undefined;
    }

    eventEmitter.removeAllListeners('EventCloseSodyoScanner');

    const subscription = eventEmitter.addListener('EventCloseSodyoScanner', () => {
      if (typeof callback === 'function') {
        callback();
      }
    });

    return () => {
      return subscription.remove();
    };
  },

  onMarkerContent: (callback) => {
    eventEmitter.removeAllListeners('EventMarkerContent');

    const subscription = eventEmitter.addListener('EventMarkerContent', (e) => {
      if (typeof callback === 'function') {
        const data = typeof e.data === 'string'
          ? JSON.parse(e.data)
          : e.data || {};
        callback(e.markerId, data);
      }
    });

    return () => {
      return subscription.remove();
    };
  },

  onModeChange: (callback) => {
    eventEmitter.removeAllListeners('ModeChangeCallback');

    const subscription = eventEmitter.addListener('ModeChangeCallback', (e) => {
      if (typeof callback === 'function') {
        callback(e);
      }
    });

    return () => {
      return subscription.remove();
    };
  },

  onCloseContent: (callback) => {
    if (Platform.OS !== 'ios') {
      return () => undefined;
    }

    RNSodyoSdk.createCloseContentListener();
    eventEmitter.removeAllListeners('EventCloseSodyoContent');

    const subscription = eventEmitter.addListener('EventCloseSodyoContent', () => {
      if (typeof callback === 'function') {
        callback();
      }
    });

    return () => {
      return subscription.remove();
    };
  },

  performMarker: (markerId, customProperties) => {
    return RNSodyoSdk.performMarker(markerId, customProperties);
  },

  startTroubleshoot: () => {
    return RNSodyoSdk.startTroubleshoot();
  },

  start: (successCallback, errorCallback) => {
    eventEmitter.removeAllListeners('EventMarkerDetectSuccess');
    eventEmitter.removeAllListeners('EventMarkerDetectError');

    RNSodyoSdk.start();

    eventEmitter.addListener('EventMarkerDetectSuccess', (e) => {
      if (typeof successCallback === 'function') {
        successCallback(e.data);
      }
    });

    eventEmitter.addListener('EventMarkerDetectError', (e) => {
      if (typeof errorCallback === 'function') {
        errorCallback(e.error);
      }
    });
  },

  removeAllListeners: () => {
    return eventEmitter.removeAllListeners();
  },

  close: () => {
    eventEmitter.removeAllListeners('EventMarkerDetectSuccess');
    eventEmitter.removeAllListeners('EventMarkerDetectError');

    return RNSodyoSdk.close();
  },

  setUserInfo: (userInfo) => {
    return RNSodyoSdk.setUserInfo(userInfo);
  },

  setScannerParams: (scannerPreferences) => {
    return RNSodyoSdk.setScannerParams(scannerPreferences);
  },

  addScannerParam: (key, value) => {
    return RNSodyoSdk.addScannerParam(key, value);
  },

  setDynamicProfileValue: (key, value) => {
    return RNSodyoSdk.setDynamicProfileValue(key, value);
  },

  setCustomAdLabel: (label) => {
    return RNSodyoSdk.setCustomAdLabel(label);
  },

  setAppUserId: (appUserId) => {
    return RNSodyoSdk.setAppUserId(appUserId);
  },

  setSodyoLogoVisible: (isVisible) => {
    return RNSodyoSdk.setSodyoLogoVisible(isVisible);
  },

  setTroubleshootMode: () => {
    return RNSodyoSdk.setTroubleshootMode();
  },

  setNormalMode: () => {
    return RNSodyoSdk.setNormalMode();
  },

  setEnv: (env) => {
    return RNSodyoSdk.setEnv(env);
  },

  getMode: () => {
    return RNSodyoSdk.getMode();
  },
};

export class Scanner extends Component {
  static defaultProps = {
    isEnabled: true,
    isTroubleShootingEnabled: false,
  };

  componentDidUpdate(prevProps: Readonly<P>, prevState: Readonly<S>, snapshot: SS) {
    if (this.props.isTroubleShootingEnabled) {
      if (Platform.OS !== 'ios') {
        return RNSodyoSdk.startTroubleshoot()
      }
    }
  }

  render () {
    const { isEnabled, isTroubleShootingEnabled, children } = this.props;
    return (
      <Fragment>
        <RNSodyoSdkView
          isEnabled={isEnabled}
          isTroubleShootingEnabled={isTroubleShootingEnabled}
          style={{ height: '100%', width: '100%' }}
        />

        <View style={styles.container} pointerEvents="box-none">
          {children}
        </View>
      </Fragment>
    );
  }
}

export const SODYO_ENV = {
  DEV: 'DEV',
  QA: 'QA',
  PROD: 'PROD',
}

const RNSodyoSdkView = requireNativeComponent('RNSodyoSdkView', Scanner, {
  nativeOnly: {},
});


const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    left: 0,
    right: 0,
    width: '100%',
    height: '100%',
    flex: 1,
  },
})
