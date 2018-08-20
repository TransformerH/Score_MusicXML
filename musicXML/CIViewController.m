//
//  CIViewController.m
//  musicXML
//
//  Created by tanhui on 2017/9/15.
//  Copyright © 2017年 tanhuiya. All rights reserved.
//

#import "CIViewController.h"
//#import <musicXML/musicXML.h>
#import <musicXML/ScoreViewController.h>
//#import "ScoreViewController.h"
#import <CIRouter/CIRouter.h>
#import "musicXML_Example-Swift.h"

@interface CIViewController ()
@property(nonatomic,strong)NSArray* pathArr;
@end

@implementation CIViewController

static NSString* FilePathCell = @"FilePathCell";


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES];
    
    NSArray* paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"xml" inDirectory:@"Resource"];
    NSMutableArray* arr = @[].mutableCopy;
    for (NSString* path in paths) {
        NSString* name = [path lastPathComponent];
        [arr addObject:@{@"name":name,
                        @"path":path}];
    }
    self.pathArr = arr.copy;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:FilePathCell];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FilePathCell];
    }
    NSDictionary* dic = self.pathArr[indexPath.row];
    cell.textLabel.text = dic[@"name"];
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.pathArr.count;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString* path = self.pathArr[indexPath.row][@"path"];
    NSString* str = [[[SwiftBridge alloc]init] scoreModuleStr];

    void(^callback)() = ^{
        NSLog(@"callback");
    };
    
    NSDictionary* param = @{
                            @"channelID":@1,
                            @"accountID":@"a98fa36bd43043e0bc1f2f76bf07643c", @"token":@"eyJhY2NvdW50SUQiOiJhOThmYTM2YmQ0MzA0M2UwYmMxZjJmNzZiZjA3NjQzYyIsInRpbWVzdGFtcCI6MTUxNTQ4NzcwOCwiZXhwaXJldGltZSI6MzE1MzYwMDAsInRva2VuU3RyaW5nIjoiOGIyZDI3ZDhlMzhkZjM2NDhhNDgzYjA1YmIzMGYyZjIifQ==",
                            @"filePath":path,
                            @"musicID":@"111",
                            @"title":@"musicXML",
                            @"type":@"work",
                            @"typeID":@"12",
                            @"mode":@1,
                            @"hasMainChannel":@1,
                            @"tempo":@"90",
                            
                            @"callback":callback,
                            @"debug":@1,
                            };
    MidiOption* option = [[MidiOption alloc] initWithTitle:param[@"title"] accountID:param[@"accountID"] channelID:param[@"channelID"] token:param[@"token"] musicID:param[@"musicID"] filePath:param[@"filePath"]];
    option.mType = @"work";
    option.mMode = CIMidiPlayerMode_MainWithAccompany;
    option.mHasMainChannel = 1;
    option.mTypeID = 1;
    option.mDebug = 1;
    option.callBack = ^{
        NSLog(@"callback");
    };
    option.mDomain = @"http://192.168.2.122:8021/index.php/";
    ScoreViewController * score = [[ScoreViewController alloc] initWithOption:option];
    [self.navigationController pushViewController:score animated:YES];
}

-(BOOL)shouldAutorotate{
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
