//
//  Connector.m
//  Pods
//
//  Created by tanhui on 2017/8/17.
//
//

#import "ConnectorViewController.h"
#import "Constants.h"


@interface ConnectorViewController() <UITableViewDelegate,UITableViewDataSource,BluethoothConnectDelegate>

@property (strong , nonatomic) UITableView *tableView;

@property (strong , nonatomic) NSArray *BleViewPerArr;

@property (copy , nonatomic)void (^successBlock)() ;
@property (copy , nonatomic)void (^errorBlock)() ;
@end

@implementation ConnectorViewController


-(instancetype)initWithSuccessBlock:(void (^)())success error:(void (^)())error{
    if ([super init]) {
        self.successBlock = success;
        self.errorBlock = error;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    [self setTableView];
    Connector * connctor = [Connector defaultConnector];
    self.mConnector = connctor;
    [connctor scan];
    connctor.connectionDelegate = self;
}

-(void)setTableView{
    _tableView = [[UITableView alloc]initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_tableView];
    
    UIButton * dissmiss = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    [dissmiss setBackgroundColor:[UIColor redColor]];
    [dissmiss setTitle:@"关闭" forState:UIControlStateNormal];
    _tableView.tableFooterView = dissmiss;
    [dissmiss addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
}

-(void)back{
    [self.mConnector stopScan];
    self.mConnector.connectionDelegate = nil;
    [self dismiss];
}

-(void)dismiss{
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"IsConnect"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IsConnect"];
    }
    
    // 将蓝牙外设对象接出，取出name，显示
    //蓝牙对象在下面环节会查找出来，被放进BleViewPerArr数组里面，是CBPeripheral对象
    CBPeripheral *per=(CBPeripheral *)_BleViewPerArr[indexPath.row];
//    NSString *bleName=[per.name substringWithRange:NSMakeRange(0, 9)];
    cell.textLabel.text = [per.name stringByAppendingString:per.identifier.UUIDString];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _BleViewPerArr.count;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CBPeripheral *peripheral=(CBPeripheral *)_BleViewPerArr[indexPath.row];
    //设定周边设备，指定代理者

    //连接设备
    [self.mConnector selectPeripheral:peripheral];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


-(void)connectSuccessPeripherals{
//    self.mIsConnected = 1;
    if (self.successBlock) {
        self.successBlock();
    }
    [self dismiss];
}

-(void)connectDisConnectPeripherals:(NSError*)error{
    CILog(@"%@",error);
//    self.mIsConnected = 0;
    if (self.errorBlock) {
        self.errorBlock();
    }
}

-(void)connectFailedPeripheralsWithError:(NSError*)error{
    if (error.localizedDescription && error.localizedDescription.length) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* action = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
//        [MBProgressHUD CI_showTitle:error.localizedDescription toView:self.view hideAfter:1.5];
    }
}

-(void)connectDidFindPeripherals:(NSArray *)periphrals{
    self.BleViewPerArr = [periphrals copy];
    [self.tableView reloadData];
}


-(void)setMConnector:(Connector *)mConnector{
    _mConnector = mConnector;
    mConnector.connectionDelegate = self;
}

-(BOOL)shouldAutorotate{
    return YES;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}
@end
