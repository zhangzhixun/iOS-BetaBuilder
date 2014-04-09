//
//  AppDelegate.m
//  iOS BetaBuilder
//
//  Created by 张志勋 on 14-4-3.
//  Copyright (c) 2014年 zhixun_zhang. All rights reserved.
//

#import "AppDelegate.h"
#import "ZipArchive.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self.generateButton setEnabled:NO];
}

- (void)applicationWillResignActive:(NSNotification *)notification{
    NSLog(@"applicationWillResignActive");
}

- (IBAction)archiveHelp:(id)sender{

    controller = [[NSWindowController alloc]initWithWindowNibName:@"HelpWindow"];
    [controller.window setTitle:@"Help me"];
    [controller.window center];
    [controller showWindow:self.window];
    [controller.window makeKeyWindow];
    [controller.window makeKeyAndOrderFront:nil];
    
}
- (IBAction)chooseIPA:(id)sender{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setPrompt:@"Select ipa"];
    [panel setAllowedFileTypes:@[@"ipa"]];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            NSArray *filePaths = [panel URLs];
            NSURL *url = [filePaths objectAtIndex:0];
            NSString *path = [[url absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            archivePath = [path substringFromIndex:7];
            [self.archiveField setStringValue:archivePath];
            
            //获取 IPA文件的信息
            NSString *zipPath = [self copyIpaToZip:archivePath];
            NSString *directoryPath = [self unzipFile:zipPath];
            NSString *appPath = [self getAppInDirectory:directoryPath];
            NSLog(@"app path :%@",appPath);
            
            NSBundle *bundle = [NSBundle bundleWithPath:appPath];
            NSString *infoPath = [bundle pathForResource:@"Info" ofType:@"plist"];
            NSDictionary *infoDic = [NSDictionary dictionaryWithContentsOfFile:infoPath];
            
            bundleName = [infoDic objectForKey:@"CFBundleDisplayName"];
            bundleId = [infoDic objectForKey:@"CFBundleIdentifier"];
            bundleVersion = [infoDic objectForKey:@"CFBundleVersion"];
            
            [self.appNameField setStringValue:bundleName];
            [self.bundleIdField setStringValue:bundleId];
            [self.bundleVersionField setStringValue:bundleVersion];
            
            [self deleteFile:zipPath];
            [self deleteFile:directoryPath];
            
            [self.generateButton setEnabled:YES];
        }
    }];

}
- (IBAction)deploymentHelp:(id)sender{
    controller = [[NSWindowController alloc]initWithWindowNibName:@"HelpWindow"];
    [controller.window setTitle:@"Help me"];
    [controller.window center];
    [controller showWindow:self.window];
    [controller.window makeKeyWindow];
    [controller.window makeKeyAndOrderFront:nil];
}
- (IBAction)generateFiles:(id)sender{
    //打开对话框，选择文件存放位置
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setCanCreateDirectories:YES];
    [panel setPrompt:@"save files"];
    [panel setTitle:@"choose a directory"];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            NSURL *url = panel.URL;
            NSString *path = [[url absoluteString] substringFromIndex:7];
            NSString *directory = [path stringByAppendingPathComponent:@"generated"];
            NSError *error;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL success = [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
            if (success) {
                
                //创建readme.txt
                NSString *readmePath = [directory stringByAppendingPathComponent:@"readme.txt"];
                NSString *content = @"readme...";
                [fileManager createFileAtPath:readmePath contents:nil attributes:nil];
                if (![content writeToFile:readmePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
                    NSLog(@"create readme error:%@",[error description]);
                }
                
                //拷贝IPA文件
                NSString *ipaPath = self.archiveField.stringValue;
                if (![fileManager copyItemAtPath:ipaPath toPath:[directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ipa",bundleName]] error:&error]) {
                    NSLog(@"copy ipa error:%@",[error description]);
                }
                
                //创建manifest.plist
                NSString *manifestPath = [directory stringByAppendingPathComponent:@"manifest.plist"];
                NSDictionary *metadata = @{@"bundle-identifier":bundleId, @"bundle-version":bundleVersion, @"kind":@"software", @"title":bundleName};
                uploadUrl = self.deploymentField.stringValue;
                NSString *url = [uploadUrl stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ipa",bundleName]];
                NSDictionary *urlData = @{@"kind":@"software-package",@"url":url};
                NSArray *assets = @[urlData];
                
                NSDictionary *item =  @{@"assets":assets, @"metadata":metadata};
                NSArray *item1 = @[item];
                NSDictionary *root = @{@"items":item1};
                
                [fileManager createFileAtPath:manifestPath contents:nil attributes:nil];
                [root writeToFile:manifestPath atomically:YES];
                
                //创建index.html文件
                NSString *htmlPath = [directory stringByAppendingPathComponent:@"index.html"];
                if (![fileManager createFileAtPath:htmlPath contents:nil attributes:nil]) {
                    NSLog(@"create index.html error");
                }
                
                NSMutableString *html = [NSMutableString stringWithCapacity:1000];
                [html appendString:@" \
                 <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"> \
                 <html xmlns=\"http://www.w3.org/1999/xhtml\"> \
                 <head> \
                 <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" /> \
                 <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0\"> \
                 <title>CamCard - Beta Release</title> \
                 <style type=\"text/css\"> \
                 body {background:#fff;margin:0;padding:0;font-family:arial,helvetica,sans-serif;text-align:center;padding:10px;color:#333;font-size:16px;} \
                 #container {width:300px;margin:0 auto;} \
                 h1 {margin:0;padding:0;font-size:14px;} \
                 p {font-size:13px;} \
                 .link {background:#ecf5ff;border-top:1px solid #fff;border:1px solid #dfebf8;margin-top:.5em;padding:.3em;} \
                 .link a {text-decoration:none;font-size:15px;display:block;color:#069;} \
                 </style> \
                 </head> \
                 <body> \
                 <div id=\"container\"> \
                 <h1>iOS 4.0 Users:</h1> \
                 <div class=\"link\"><a href=\"itms-services://?action=download-manifest&url=\
                 "];
                NSString *downloadUrl = [self.deploymentField.stringValue stringByAppendingPathComponent:@"manifest.plist"];
                [html appendString:downloadUrl];
                [html appendString:@"\">Tap Here to Install<br />"];
                [html appendString:bundleName];
                [html appendString:@"<br />On Your Device</a></div>\
                 <p><strong>Link didn't work?</strong><br />\
                 Make sure you're visiting this page on your device, not your computer.</p>\
                 </div>\
                 </body>\
                 </html>\
                 "];
                if (![html writeToFile:htmlPath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
                    NSLog(@"write index.html error:%@",[error description]);
                };
                
                //创建zip文件, 为iOS 4.0 以前版本服务
                [self zipFile:directory];
            }
            
        }
    }];
    
    
}

/**
 压缩zip包
 @param path: 存放路径
 @return
 @exception
 */

- (void)zipFile:(NSString *)path{
    ZipArchive *zip = [[ZipArchive alloc]init];
    NSString* l_zipfile = [path stringByAppendingString:@"/archive.zip"] ;
    
    NSString* ipaPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ipa",self.appNameField.stringValue]] ;
    NSString* provisionPath = [path stringByAppendingPathComponent:@"privision.mobileprovision"] ;
    
    BOOL ret = [zip CreateZipFile2:l_zipfile];
    if (ret) {
        ret = [zip addFileToZip:ipaPath newname:@"application.ipa"];
        ret = [zip addFileToZip:provisionPath newname:@"privision.mobileprovision"];
    }
    
    if( ![zip CloseZipFile2] )
    {
        l_zipfile = @"";
    }
}

// 解压缩zip包
- (NSString *)unzipFile:(NSString *)filePath{
    ZipArchive* zip = [[ZipArchive alloc] init];
    

    NSString *targetPath = [[filePath componentsSeparatedByString:@"."] firstObject];
    if( [zip UnzipOpenFile:filePath] )
    {
        BOOL ret = [zip UnzipFileTo:targetPath  overWrite:YES];
        if( NO==ret )
        {
        }
        [zip UnzipCloseFile];
        return targetPath;
    }
    return nil;
}

// 将ipa改为zip
- (NSString *)changeIpaToZip:(NSString *)filePath{
    NSString *targetFile = [[[filePath componentsSeparatedByString:@"."] firstObject] stringByAppendingPathExtension:@"zip"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:filePath]) {
        NSError *error;
        if (![fm moveItemAtPath:filePath toPath:targetFile error:&error]) {
            NSLog(@"%@",[error description]);
        }
        return targetFile;
    }
    return nil;
}
// 将ipa复制新的为zip
- (NSString *)copyIpaToZip:(NSString *)filePath{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSData *data = [fm contentsAtPath:filePath];

    NSString *targetFile = [[[filePath componentsSeparatedByString:@"."] firstObject] stringByAppendingPathExtension:@"zip"];
    if ([fm createFileAtPath:targetFile contents:data attributes:nil]) {
        return targetFile;
    }
    return nil;
}

//获取Payload下的app路径
- (NSString *)getAppInDirectory:(NSString *)path{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSString *payloadPath = [path stringByAppendingPathComponent:@"Payload"];
    NSString *appPath;
    NSArray *files = [fm contentsOfDirectoryAtPath:payloadPath error:&error];
    for (NSString *file in files) {
        if ([[file pathExtension] isEqualToString:@"app"]) {
            appPath = [payloadPath stringByAppendingPathComponent:file];
            return appPath;
        }
    }
    return nil;
}

- (BOOL)deleteFile:(NSString *)path{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    if (![fm removeItemAtPath:path error:&error]) {
        NSLog(@"%@",[error description]);
        return NO;
    }
    return YES;
}


@end
