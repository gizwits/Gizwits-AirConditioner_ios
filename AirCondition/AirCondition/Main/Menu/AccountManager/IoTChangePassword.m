/**
 * IoTChangePassword.m
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "IoTChangePassword.h"
#import <IoTProcessModel/IoTProcessModel.h>
#import "IoTAlertView.h"
#import "IoTMainController.h"

@interface IoTChangePassword () <XPGWifiSDKDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textOldPass;
@property (weak, nonatomic) IBOutlet UITextField *textNewPass;

@end

@implementation IoTChangePassword

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"修改密码";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"return_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [XPGWifiSDK sharedInstance].delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [XPGWifiSDK sharedInstance].delegate = nil;
}

- (IoTMainController *)mainCtrl
{
    SlideNavigationController *navCtrl = [SlideNavigationController sharedInstance];
    for(int i=(int)(navCtrl.viewControllers.count-1); i>0; i--)
    {
        if([navCtrl.viewControllers[i] isKindOfClass:[IoTMainController class]])
            return navCtrl.viewControllers[i];
    }
    return nil;
}

- (IBAction)onConfirm:(id)sender {
    if(self.textNewPass.text.length < 6 || self.textNewPass.text.length > 16)
    {
        [[[IoTAlertView alloc] initWithMessage:@"新密码长度必须在 6-16 之间" delegate:nil titleOK:@"确定"] show:YES];
        return;
    }
    
    if(![[IoTProcessModel sharedModel] validatePassword:self.textNewPass.text])
    {
        [[[IoTAlertView alloc] initWithMessage:@"新密码格式不正确，请重新输入" delegate:nil titleOK:@"确定"] show:YES];
        return;
    }
    
    MBProgressHUD *hud = IoTAppDelegate.hud;
    hud.labelText = @"修改密码中，请稍候...";
    [hud show:YES];
    
    [[XPGWifiSDK sharedInstance] changeUserPassword:[IoTProcessModel sharedModel].currentToken oldPassword:self.textOldPass.text newPassword:self.textNewPass.text];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didChangeUserPassword:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    [IoTAppDelegate.hud hide:YES];
    
    if([error intValue] == 0)
    {
        [[[IoTAlertView alloc] initWithMessage:@"修改成功" delegate:nil titleOK:@"确定"] show:YES];
    }
    else
    {
        NSLog(@"code=%@ message=%@", error, errorMessage);
        [[[IoTAlertView alloc] initWithMessage:@"密码输入有误，请重新输入" delegate:nil titleOK:@"确定"] show:YES];
    }
}

@end
