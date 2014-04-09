//
//  AppDelegate.h
//  iOS BetaBuilder
//
//  Created by 张志勋 on 14-4-3.
//  Copyright (c) 2014年 zhixun_zhang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    NSString *bundleId;
    NSString *bundleVersion;
    NSString *bundleName;
    NSString *uploadUrl;
    
    NSString *archivePath;

    NSWindowController *controller;
}

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSTextField *archiveField;
@property (assign) IBOutlet NSTextField *bundleIdField;
@property (assign) IBOutlet NSTextField *bundleVersionField;
@property (assign) IBOutlet NSTextField *appNameField;
@property (assign) IBOutlet NSTextField *deploymentField;

@property (assign) IBOutlet NSButton *generateButton;


- (IBAction)archiveHelp:(id)sender;
- (IBAction)chooseIPA:(id)sender;
- (IBAction)deploymentHelp:(id)sender;
- (IBAction)generateFiles:(id)sender;

@end
