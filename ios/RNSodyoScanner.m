//
//  RNSodyoCallback.m
//  RNSodyoSdk
//
//  Created by Bogdan on 20.06.2022.
//
#import "RNSodyoScanner.h"
#import <Foundation/Foundation.h>

static UIViewController* _sharedScanner = nil;

@implementation RNSodyoScanner

+ (UIViewController *) getSodyoScanner {
  return _sharedScanner;
}

+ (void) setSodyoScanner:(UIViewController*) newSodyoScanner {
  if(_sharedScanner != newSodyoScanner) {
    _sharedScanner = newSodyoScanner;
  }
}

@end