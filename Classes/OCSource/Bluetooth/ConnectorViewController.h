//
//  Connector.h
//  Pods
//
//  Created by tanhui on 2017/8/17.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Connector.h"

@interface ConnectorViewController : UIViewController

@property(nonatomic, strong)Connector* mConnector;

-(instancetype)initWithSuccessBlock:(void (^)())success error:(void (^)())error;

@end
