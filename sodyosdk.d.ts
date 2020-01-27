import * as React from 'react'

declare const _default: {
  init (apiKey: string, successCallback?: () => void, errorCallback?: (msg: string) => void): void
  onError (callback: (err: string) => void): () => void,
  onCloseScanner (callback: () => void): () => void,
  onCloseContent (callback: () => void): () => void,
  start (successCallback?: (immediateData?: string) => void, errorCallback?: (msg: string) => void): void
  close (): void
  setUserInfo (userInfo: { [key: string]: string | number }): void
  setScannerParams (scannerPreferences: { [key: string]: string | number }): void
  setCustomAdLabel (label: string): void
  setAppUserId (appUserId: string): void
  setOverlayView (html: string): void
  setOverlayCallback (callbackName: string, callback: () => void): void
  removeAllListeners (eventType?: string): void
  onMarkerContent (callback: (markerId: string, data: { [key: string]: any }) => void): () => void,
  performMarker (markerId: string): void,
  setSodyoLogoVisible (isVisible: boolean): void,
}

interface IScannerProps {
  isEnabled?: boolean
}

export declare class Scanner extends React.PureComponent<IScannerProps> {
}

export default _default
