//
//  Connector.m
//  Pods
//
//  Created by tanhui on 2017/8/17.
//
//

#import "Connector.h"
#import "Constants.h"
#import "BleMidiParser.h"

#define MIDI_SERVICE_UUID  @"03B80E5A-EDE8-4B33-A751-6CE34EC4C700"
#define MIDI_CHARACTER_UUID @"7772E5DB-3868-4112-A1A9-F2669D106BF3"

typedef NS_ENUM(NSInteger, BluetoothState){
    BluetoothStateDisconnect = 0,
    BluetoothStateScanSuccess,
    BluetoothStateScaning,
    BluetoothStateConnected,
    BluetoothStateConnecting
};

typedef NS_ENUM(NSInteger, BluetoothFailState){
    BluetoothFailStateUnExit = 0,
    BluetoothFailStateUnKnow,
    BluetoothFailStateByHW,
    BluetoothFailStateByOff,
    BluetoothFailStateUnauthorized,
    BluetoothFailStateByTimeout
};

@interface Connector ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (strong , nonatomic) CBCentralManager *manager;//中央设备
@property (assign , nonatomic) BluetoothFailState bluetoothFailState;
@property (assign , nonatomic) BluetoothState bluetoothState;
@property (strong , nonatomic) CBPeripheral * discoveredPeripheral;//周边设备
@property (strong , nonatomic) CBCharacteristic *characteristic1;//周边设备服务特性
@property (strong , nonatomic) NSMutableArray* mPeripheralArr;
@property (strong , nonatomic) BleMidiParser* mBleParser;
@property (assign , nonatomic) BOOL mIsrecording;

@end

@implementation Connector

static Connector* connector = nil;
+(instancetype)defaultConnector{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        connector = [[Connector alloc]init];
    });
    return connector;
}

-(instancetype)init{
    if ([super init]) {
        self.mPeripheralArr = @[].mutableCopy;
        self.manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        self.manager.delegate = self;
    }
    return self;
}

-(void)selectPeripheral:(CBPeripheral*)periphera{
    [self.manager stopScan];
    _discoveredPeripheral = periphera;
    _discoveredPeripheral.delegate = self;
    [_manager connectPeripheral:periphera
                        options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES}];
}

-(void)cancelConnection{
    if(self.discoveredPeripheral){
        [self.manager cancelPeripheralConnection:self.discoveredPeripheral];

    }
}

-(void)stopScan {
    [self.manager stopScan];
}

// 获取当前设备
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    CILog(@"%@",peripheral);
    
    // 设置设备代理
    [peripheral setDelegate:self];
    // 大概获取服务和特征
    [peripheral discoverServices:nil];
    
    //或许只获取你的设备蓝牙服务的uuid数组，一个或者多个
    //[peripheral discoverServices:@[[CBUUID UUIDWithString:@""],[CBUUID UUIDWithString:@""]]];
    
    
    CILog(@"Peripheral Connected");
    
    [self stopScan];
    
    CILog(@"Scanning stopped");
    
    _bluetoothState=BluetoothStateConnected;
    
    [self.connectionDelegate connectSuccessPeripherals];
    _isConnected = YES;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    _isConnected = NO;
    if ([self.connectionDelegate respondsToSelector:@selector(connectDisConnectPeripherals:)]) {
        [self.connectionDelegate connectDisConnectPeripherals:error];
    }
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    CILog(@"Failed Connect");
    _isConnected = NO;
}

-(void)scan{
    //判断状态开始扫瞄周围设备 第一个参数为空则会扫瞄所有的可连接设备  你可以
    //指定一个CBUUID对象 从而只扫瞄注册用指定服务的设备
    //scanForPeripheralsWithServices方法调用完后会调用代理CBCentralManagerDelegate的
    //- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI方法
    [self.manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:MIDI_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO }];
    //记录目前是扫描状态
    _bluetoothState = BluetoothStateScaning;
    //清空所有外设数组
    [self.mPeripheralArr removeAllObjects];
    //如果蓝牙状态未开启，提示开启蓝牙
    if(_bluetoothFailState==BluetoothFailStateByOff)
    {
        CILog(@"%@",@"检查您的蓝牙是否开启后重试");
    }
    
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (central.state != CBCentralManagerStatePoweredOn) {
        CILog(@"fail, state is off.");
        NSString* failStr = nil;
        switch (central.state) {
            case CBCentralManagerStatePoweredOff:
                failStr = @"连接失败了\n请您再检查一下您的手机蓝牙是否开启，\n然后再试一次吧";
                _bluetoothFailState = BluetoothFailStateByOff;
                break;
            case CBCentralManagerStateResetting:
                failStr = @"连接超时，请重试";
                _bluetoothFailState=BluetoothFailStateByTimeout;
                break;
            case CBCentralManagerStateUnsupported:
                failStr = @"检测到您的手机不支持蓝牙4.0\n所以建立不了连接.建议更换您\n的手机再试试";
                _bluetoothFailState = BluetoothFailStateByHW;
                break;
            case CBCentralManagerStateUnauthorized:
                failStr = @"连接失败了\n请您再检查一下您的手机蓝牙是否开启，\n然后再试一次吧";
                _bluetoothFailState = BluetoothFailStateUnauthorized;
                break;
            case CBCentralManagerStateUnknown:
                failStr = @"未知错误，再试一次吧";
                _bluetoothFailState = BluetoothFailStateUnKnow;
                break;
            default:
                break;
        }
        NSError* error = [NSError errorWithDomain:@"com.ci123.bleDemo" code:-1 userInfo:@{NSLocalizedDescriptionKey:failStr}];
        if ([self.connectionDelegate respondsToSelector:@selector(connectFailedPeripheralsWithError:)]) {
            [self.connectionDelegate connectFailedPeripheralsWithError:error];
        }
        return;
    }
    _bluetoothFailState = BluetoothFailStateUnExit;
    // ... so start scanning

    [self scan];
}


- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    if (peripheral == nil||peripheral.identifier == nil/*||peripheral.name == nil*/){
        return;
    }
    //判断是否存在@"你的设备名"
    //如果从搜索到的设备中找到指定设备名，和BleViewPerArr数组没有它的地址
    //加入BleViewPerArr数组
    if(peripheral.name  && [ self.mPeripheralArr containsObject:peripheral]==NO ){
        [self.mPeripheralArr addObject:peripheral];
    }
    _bluetoothFailState = BluetoothFailStateUnExit;
    _bluetoothState = BluetoothStateScanSuccess;
    
    if (self.connectionDelegate && [self.connectionDelegate respondsToSelector:@selector(connectDidFindPeripherals:)]) {
        [self.connectionDelegate connectDidFindPeripherals:self.mPeripheralArr];
    }
}


// 获取当前设备服务services
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error) {
        CILog(@"Error discovering services: %@", [error localizedDescription]);
        return;
    }
    CILog(@"所有的servicesUUID%@",peripheral.services);
    
    //遍历所有service
    for (CBService *service in peripheral.services){
        CILog(@"服务%@",service.UUID);
        //找到你需要的servicesuuid
        if ([service.UUID isEqual:[CBUUID UUIDWithString:MIDI_SERVICE_UUID]]){
            //监听它
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
    CILog(@"此时链接的peripheral：%@",peripheral);
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error){
        CILog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics){
        //发现特征
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:MIDI_CHARACTER_UUID]]){
            //保存characteristic特征值对象
            //以后发信息也是用这个uuid
            _characteristic1 = characteristic;
            [_discoveredPeripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error){
        CILog(@"Error updating value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
    if(self.mIsrecording){
        struct timeval now;
        gettimeofday(&now, NULL);
        long msec = 0;
        if (startTime.tv_sec || startTime.tv_usec ){
            msec = (now.tv_sec - startTime.tv_sec)*1000 +
            (now.tv_usec - startTime.tv_usec)/1000;
        }
        int length = [characteristic.value length];
        [self.mBleParser parse:[characteristic.value bytes] length:length atMS:msec];
    }
}

-(void)prepareRecording{
    startTime.tv_usec = startTime.tv_sec = 0;
    self.mIsrecording = YES;
}

-(void)beginRecording{
    gettimeofday(&startTime, NULL);
}
-(void)stopRecording{
    self.mIsrecording = NO;
}

-(BOOL)isRecording{
    return self.mIsrecording;
}

-(BleMidiParser *)mBleParser{
    if (!_mBleParser) {
        _mBleParser = [[BleMidiParser alloc]init];
    }
    return _mBleParser;
}

@end
