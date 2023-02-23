import * as React from 'react'

type TEnv = 'DEV' | 'QA' | 'PROD';

declare const _default: {
  init (apiKey: string, successCallback?: () => void, errorCallback?: (msg: string) => void, env?: TEnv): void
  onError (callback: (err: string) => void): () => void,
  onCloseScanner (callback: () => void): () => void,
  onCloseContent (callback: () => void): () => void,
  start (successCallback?: (immediateData?: string) => void, errorCallback?: (msg: string) => void): void
  close (): void
  setUserInfo (userInfo: { [key: string]: string | number }): void
  setScannerParams (scannerPreferences: { [key: string]: string }): void
  addScannerParam (key: string, value: string): void
  setDynamicProfileValue (key: string, value: string): void
  setCustomAdLabel (label: string): void
  setAppUserId (appUserId: string): void
  removeAllListeners (eventType?: string): void
  onMarkerContent (callback: (markerId: string, data: { [key: string]: any }) => void): () => void,
  onModeChange (callback: (data: ISodyoMode) => void): () => void,
  performMarker (markerId: string, customProperties: { [key: string]: any }): void,
  startTroubleshoot (): void,
  setSodyoLogoVisible (isVisible: boolean): void,
  setTroubleshootMode (): void,
  setNormalMode (): void,
  getMode (): EScannerViewMode,
  setEnv(env: TEnv): void,
}

interface IScannerProps {
  isEnabled?: boolean
  isTroubleShootingEnabled?: boolean
}

export declare class Scanner extends React.PureComponent<IScannerProps> {
}

export declare const SODYO_ENV: {
  [key in TEnv]: TEnv
}

export enum EScannerViewMode {
  NORMAL = 'Normal',
  TROUBLESHOOT = 'Troubleshoot',
  DEVICE_TESTER = 'DeviceTester'
}

export interface ISodyoMode {
  newMode: EScannerViewMode,
  oldMode: EScannerViewMode,
}

export default _default
