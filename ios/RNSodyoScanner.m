//
//  RNSodyoCallback.m
//  RNSodyoSdk
//
//  Created by Bogdan on 20.06.2022.
//
#import "RNSodyoScanner.h"
#import <Foundation/Foundation.h>

@implementation RNSodyoScanner

+ (UIViewController *) getSodyoScanner {
  return sodyoScanner;
}

+ (void) setSodyoScanner:(UIViewController*) newSodyoScanner {
  if(sodyoScanner != newSodyoScanner) {
    sodyoScanner = newSodyoScanner;
  }
}

@end
// implementation of getter and setter
