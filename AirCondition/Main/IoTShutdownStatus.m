/**
 * IoTShutdownStatus.m
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

#import "IoTShutdownStatus.h"
#import "IoTMainController.h"
#import "IoTTimingSelection.h"
#import "IoTMainMenu.h"

@interface IoTShutdownStatus () <IoTTimingSelectionDelegate>
{
    IoTTimingSelection *_timingSelection;
}

@property (nonatomic, strong) XPGWifiDevice *device;
@property (weak, nonatomic) IBOutlet UIButton *btnOnTiming;

@end

@implementation IoTShutdownStatus

- (id)initWithDevice:(XPGWifiDevice *)device
{
    self = [super init];
    if(self)
    {
        self.device = device;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"移动空调";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu"] style:UIBarButtonItemStylePlain target:[SlideNavigationController sharedInstance] action:@selector(toggleLeftMenu)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self onUpdateTiming];
    [self.mainCtrl addObserver:self forKeyPath:@"onTiming" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //更新侧边菜单数据
    [((IoTMainMenu *)[SlideNavigationController sharedInstance].leftMenu).tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mainCtrl removeObserver:self forKeyPath:@"onTiming"];
    [_timingSelection hide:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - action
- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onPowerOn:(id)sender {
    [self onBack];
    [self.mainCtrl writeDataPoint:IoTDeviceWriteOnTiming value:@0];
    [self.mainCtrl writeDataPoint:IoTDeviceWriteOnOff value:@1];
}

- (IBAction)onOnTiming:(id)sender {
    _timingSelection = [[IoTTimingSelection alloc] initWithTitle:@"定时开机" delegate:self currentValue:self.mainCtrl.onTiming==0?24:(self.mainCtrl.onTiming-1)];
    [_timingSelection show:YES];
}

- (void)onUpdateTiming {
    NSString *title = @" 定时开机";
    if(self.mainCtrl.onTiming != 0)
        title = [NSString stringWithFormat:@" %@小时后开机", @(self.mainCtrl.onTiming)];
    
    [self.btnOnTiming setTitle:title forState:UIControlStateNormal];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self onUpdateTiming];
}

#pragma mark - delegate
- (void)IoTTimingSelectionDidConfirm:(IoTTimingSelection *)selection withValue:(NSInteger)value
{
    if(value == 24)
        self.mainCtrl.onTiming = 0;
    else
        self.mainCtrl.onTiming = value+1;
    [self.mainCtrl writeDataPoint:IoTDeviceWriteOnTiming value:@(self.mainCtrl.onTiming)];
    
    //更新界面上的数据
    [self onUpdateTiming];
}

@end
