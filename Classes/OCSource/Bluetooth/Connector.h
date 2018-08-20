//
//  Connector.h
//  Pods
//
//  Created by tanhui on 2017/8/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#include <sys/time.h>

@protocol BluethoothConnectDelegate <NSObject>

-(void)connectSuccessPeripherals;

-(void)connectFailedPeripheralsWithError:(NSError*)error;

-(void)connectDisConnectPeripherals:(NSError*)error;

@optional

-(void)connectDidFindPeripherals:(NSArray*)periphrals;

-(double)getMSPerQuarter;

@end


@interface Connector : NSObject{
    struct timeval startTime;
}

+(instancetype)defaultConnector;

@property(nonatomic, weak) id <BluethoothConnectDelegate> connectionDelegate;
@property(nonatomic, assign, readonly)BOOL isConnected;
-(void)prepareRecording;
-(void)beginRecording;
-(void)stopRecording;

-(BOOL)isRecording;

-(void)selectPeripheral:(CBPeripheral*)periphera;
-(void)cancelConnection;
-(void)scan;
-(void)stopScan;

@end
