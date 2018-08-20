//
//  Log.m
//  Pods
//
//  Created by tanhui on 2017/9/1.
//
//

#import "Log.h"
#import "Constants.h"

@implementation Log

static NSString* logStr = @"";

+ (void)clearTempLog {
    logStr = @"";
//    NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
//    NSString *homePath = [paths objectAtIndex:0];
//    NSString *filePath = [homePath stringByAppendingPathComponent:@"tempFile"];
//    [@"" writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void)saveLogFile:(NSString*)filename{
    NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *homePath = [paths objectAtIndex:0];
//    NSString *filePath = [homePath stringByAppendingPathComponent:@"tempFile"];
//
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *datestr = [dateFormatter stringFromDate:[NSDate date]];
    datestr = [filename stringByAppendingString:datestr];
    NSString *destPath = [homePath stringByAppendingPathComponent:datestr];
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError* error = nil;
//    [fileManager copyItemAtPath:filePath toPath:destPath error:&error];
    NSError* error = nil;
    [logStr writeToFile:destPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error){
        CILog(@"failed saved %@",destPath);
    }else {
        CILog(@"success saved %@",destPath);
    }
    [self clearTempLog];
}

+ (void)writefile:(int)midiEventChannel note:(int)midiEventNote velocity:(int)midiEventVelocity tick:(double)tick remark:(NSString*)remark{
    
    NSString* string = [NSString stringWithFormat:@"%@--(channel, starttime, notenumber):[%d,%ld,%d]\n",remark,midiEventChannel,(int)tick,midiEventNote];
//    CILog(@"-- %@",string);
    logStr = [logStr stringByAppendingString:string];
    return;
    NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *homePath = [paths objectAtIndex:0];
    NSString *filePath = [homePath stringByAppendingPathComponent:@"tempFile"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:filePath]) //如果不存在
    {
        [string writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        return;
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    
    [fileHandle seekToEndOfFile];  //将节点跳到文件的末
    
    NSData* stringData  = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    [fileHandle writeData:stringData]; //追加写入数据
    
    [fileHandle closeFile];
}

@end
