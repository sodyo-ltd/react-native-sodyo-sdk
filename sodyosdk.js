import { NativeModules, NativeEventEmitter, Platform } from 'react-native';

const { RNSodyoSdk } = NativeModules;

const eventEmitter = new NativeEventEmitter(RNSodyoSdk);
let callbacks = {};

function registerCallback (name, callback) {
  if (!name || typeof callback !== 'function') {
    return false;
  }
  callbacks[name] = callback;
}

export default {
  init: (apiKey, successCallabck, errorCallback) => {
    return RNSodyoSdk.init(apiKey, successCallabck, errorCallback);
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
          : e.data || {}
        callback(e.markerId, data);
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

  performMarker: (markerId) => {
    return RNSodyoSdk.performMarker(markerId);
  },

  start: (successCallabck, errorCallback) => {
    eventEmitter.removeAllListeners('EventMarkerDetectSuccess');
    eventEmitter.removeAllListeners('EventMarkerDetectError');
    eventEmitter.removeAllListeners('EventWebViewCallback');

    RNSodyoSdk.start();

    eventEmitter.addListener('EventMarkerDetectSuccess', (e) => {
      if (typeof successCallabck === 'function') {
        successCallabck(e.data);
      }
    });

    eventEmitter.addListener('EventMarkerDetectError', (e) => {
      if (typeof errorCallback === 'function') {
        errorCallback(e.error);
      }
    });

    eventEmitter.addListener('EventWebViewCallback', (e) => {
      if (
        e &&
        e.callback &&
        callbacks.hasOwnProperty(e.callback) &&
        typeof callbacks[e.callback] === 'function'
      ) {
        callbacks[e.callback]();
      }
    });
  },

  removeAllListeners: () => {
    callbacks = {};
    return eventEmitter.removeAllListeners();
  },

  close: () => {
    eventEmitter.removeAllListeners('EventMarkerDetectSuccess');
    eventEmitter.removeAllListeners('EventMarkerDetectError');
    eventEmitter.removeAllListeners('EventWebViewCallback');

    return RNSodyoSdk.close();
  },

  setUserInfo: (userInfo) => {
    return RNSodyoSdk.setUserInfo(userInfo);
  },

  setScannerParams: (scannerPreferences) => {
    return RNSodyoSdk.setScannerParams(scannerPreferences);
  },

  setCustomAdLabel: (label) => {
    return RNSodyoSdk.setCustomAdLabel(label);
  },

  setAppUserId: (appUserId) => {
    return RNSodyoSdk.setAppUserId(appUserId);
  },

  setOverlayView: (html) => {
    return RNSodyoSdk.setOverlayView(html);
  },

  setOverlayCallback: (callbackName, callback) => {
    return registerCallback(callbackName, callback);
  },

  setSodyoLogoVisible: (isVisible) => {
    return RNSodyoSdk.setSodyoLogoVisible(isVisible);
  },
};


