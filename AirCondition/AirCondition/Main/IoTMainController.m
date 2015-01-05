/**
 * IoTMainController.m
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

#import "IoTMainController.h"
#import "IoTShutdownStatus.h"
#import "IoTTimingSelection.h"
#import "IoTRecord.h"
#import "IoTFaultList.h"
#import "IoTAlertView.h"
#import "IoTMainMenu.h"
#import "UICircularSlider.h"

#define ALERT_TAG_SHUTDOWN          1
#define AIRCONDITION_MODE_COUNT     5

@interface IoTMainController () <UIAlertViewDelegate, IoTTimingSelectionDelegate, IoTAlertViewDelegate>
{
    //数据点的临时变量
    BOOL bSwitch;
    NSInteger iOnTiming;
    NSInteger iOffTiming;
    NSInteger iMode;
    NSInteger iSetTemp;
    NSInteger iFanSpeed;
    BOOL bFanSwing;
    NSInteger iTemp;
    
    //临时数据
    NSArray *modeImages, *modeTexts;
    
    //提示框
    IoTAlertView *_alertView;
    
    //时间选择
    IoTTimingSelection *_timingSelection;
}

//全局的
@property (weak, nonatomic) IBOutlet UIView           *globalView;

//模式
@property (weak, nonatomic) IBOutlet UIImageView      *imageMode;
@property (weak, nonatomic) IBOutlet UILabel          *textMode;

//圈圈
@property (weak, nonatomic) IBOutlet UICircularSlider *sliderCircular;
@property (weak, nonatomic) IBOutlet UILabel          *textCurrentTemp;
@property (weak, nonatomic) IBOutlet UILabel          *textSetupTemp;
@property (weak, nonatomic) IBOutlet UILabel          *textUnit1;
@property (weak, nonatomic) IBOutlet UILabel          *textUnit2;

//风速
@property (weak, nonatomic) IBOutlet UIButton         *btnLow;
@property (weak, nonatomic) IBOutlet UILabel          *textLow;
@property (weak, nonatomic) IBOutlet UIButton         *btnMid;
@property (weak, nonatomic) IBOutlet UILabel          *textMid;
@property (weak, nonatomic) IBOutlet UIButton         *btnHigh;
@property (weak, nonatomic) IBOutlet UILabel          *textHigh;
@property (weak, nonatomic) IBOutlet UIButton         *btnShake;
@property (weak, nonatomic) IBOutlet UILabel          *textShake;

//摄氏度和华氏度的切换
@property (weak, nonatomic) IBOutlet UIButton         *btnTempUnit;

//工具条
@property (weak, nonatomic) IBOutlet UILabel          *textShutdown;

@end

@implementation IoTMainController

- (id)initWithDevice:(XPGWifiDevice *)device
{
    self = [super init];
    if(self)
    {
        if(nil == device)
        {
            NSLog(@"warning: device can't be null.");
            return nil;
        }
        self.device = device;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu"] style:UIBarButtonItemStylePlain target:[SlideNavigationController sharedInstance] action:@selector(toggleLeftMenu)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_start"] style:UIBarButtonItemStylePlain target:self action:@selector(onPower)];
    
    //圈圈外面预留15px
    self.sliderCircular.transform = CGAffineTransformMakeRotation(M_PI);
    self.sliderCircular.sliderStyle = UICircularSliderStyleCircle;
    self.sliderCircular.minimumValue = 16;
    self.sliderCircular.maximumValue = 30;
    self.sliderCircular.minimumTrackTintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"regulate_bar-10"]];
    self.sliderCircular.maximumTrackTintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"regulate_bar"]];
    [self.sliderCircular addTarget:self action:@selector(onUpdateProgress:) forControlEvents:UIControlEventValueChanged];
    [self.sliderCircular addTarget:self action:@selector(onSliderTouchedUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.sliderCircular addTarget:self action:@selector(onSliderTouchedUpInside:) forControlEvents:UIControlEventTouchUpOutside];
    [self setTempSliderEnabled:YES];
}

- (void)initDevice
{
    //加载页面时，清除旧的故障报警记录
    [[IoTRecord sharedInstance] clearAllRecord];
    [self onUpdateAlarm];
    
    bSwitch = 0;
    bFanSwing = 0;
    iMode = 0;
    iFanSpeed = -1;
    self.onTiming = 0;
    iOffTiming = 0;
    iSetTemp = 16;
    iTemp = 0;
    
    /**
     * 更新到 UI
     */
    [self selectFanSwing:bFanSwing sendToDevice:NO];
    [self selectFanSpeed:iFanSpeed sendToDevice:NO];
    [self selectMode:iMode sendToDevice:NO];
    [self onUpdateTemp:YES];
    self.view.userInteractionEnabled = bSwitch;
    
    //更新关机时间
    [self onUpdateShutdownText];
    
    self.device.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initDevice];
    
    [self.view addObserver:self forKeyPath:@"userInteractionEnabled" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //设备已解除绑定，或者断开连接，退出
    if(![self.device isBind:[IoTProcessModel sharedModel].currentUid] || !self.device.isConnected)
    {
        [self onDisconnected];
        return;
    }
    
    //更新侧边菜单数据
    [((IoTMainMenu *)[SlideNavigationController sharedInstance].leftMenu).tableView reloadData];

    //在页面加载后，自动更新数据
    if(self.device.isOnline)
    {
        IoTAppDelegate.hud.labelText = @"正在更新数据...";
        [IoTAppDelegate.hud showAnimated:YES whileExecutingBlock:^{
            sleep(61);
        }];
        [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
    }
    
    self.view.userInteractionEnabled = bSwitch;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.view removeObserver:self forKeyPath:@"userInteractionEnabled"];

    if([self.navigationController.viewControllers indexOfObject:self] > self.navigationController.viewControllers.count)
        self.device.delegate = nil;
    
    //防止 delegate 出错，退出之前先关掉弹出框
    [_alertView hide:YES];
    [_timingSelection hide:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data Point
- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value
{
    NSDictionary *data = nil;
    switch (dataPoint) {
        case IoTDeviceWriteUpdateData:
            data = @{DATA_CMD: @(IoTDeviceCommandRead)};
            break;
        case IoTDeviceWriteOnOff:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_SWITCH: value}};
            break;
        case IoTDeviceWriteFanSwing:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_FAN_SWING: value}};
            break;
        case IoTDeviceWriteMode:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_MODE: value}};
            break;
        case IoTDeviceWriteFanSpeed:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_FAN_SPEED: value}};
            break;
        case IoTDeviceWriteOnTiming:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_ON_TIMING: value}};
            break;
        case IoTDeviceWriteOffTiming:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_OFF_TIMING: value}};
            break;
        case IoTDeviceWriteTemperature:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite), DATA_ENTITY: @{DATA_ATTR_SET_TEMP: value}};
            break;
        default:
            NSLog(@"Error: write invalid datapoint, skip.");
            return;
    }
    
    NSLog(@"Write data: %@", data);
    [self.device write:data];
}

- (id)readDataPoint:(IoTDeviceDataPoint)dataPoint data:(NSDictionary *)data
{
    if(![data isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read data, error data format.");
        return nil;
    }
    
    NSNumber *nCommand = [data valueForKey:DATA_CMD];
    if(![nCommand isKindOfClass:[NSNumber class]])
    {
        NSLog(@"Error: could not read cmd, error cmd format.");
        return nil;
    }
    
    int nCmd = [nCommand intValue];
    if(nCmd != IoTDeviceCommandResponse && nCmd != IoTDeviceCommandNotify)
    {
        NSLog(@"Error: command is invalid, skip.");
        return nil;
    }
    
    NSDictionary *attributes = [data valueForKey:DATA_ENTITY];
    if(![attributes isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read attributes, error attributes format.");
        return nil;
    }
    
    switch (dataPoint) {
        case IoTDeviceWriteOnOff:
            return [attributes valueForKey:DATA_ATTR_SWITCH];
        case IoTDeviceWriteFanSwing:
            return [attributes valueForKey:DATA_ATTR_FAN_SWING];
        case IoTDeviceWriteMode:
            return [attributes valueForKey:DATA_ATTR_MODE];
        case IoTDeviceWriteFanSpeed:
            return [attributes valueForKey:DATA_ATTR_FAN_SPEED];
        case IoTDeviceWriteOnTiming:
            return [attributes valueForKey:DATA_ATTR_ON_TIMING];
        case IoTDeviceWriteOffTiming:
            return [attributes valueForKey:DATA_ATTR_OFF_TIMING];
        case IoTDeviceWriteTemperature:
            return [attributes valueForKey:DATA_ATTR_SET_TEMP];
        case IoTDeviceReadTemperature:
            return [attributes valueForKey:DATA_ATTR_ROOM_TEMP];
        default:
            NSLog(@"Error: read invalid datapoint, skip.");
            break;
    }
    return nil;
}

- (CGFloat)prepareForUpdateFloat:(NSString *)str value:(CGFloat)value
{
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        CGFloat newValue = [str floatValue];
        if(newValue != value)
        {
            value = newValue;
        }
    }
    return value;
}

- (NSInteger)prepareForUpdateInteger:(NSString *)str value:(NSInteger)value
{
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        NSInteger newValue = [str integerValue];
        if(newValue != value)
        {
            value = newValue;
        }
    }
    return value;
}

- (void)setTempSliderEnabled:(BOOL)enabled
{
    self.sliderCircular.userInteractionEnabled = enabled;
    if(!enabled)
        self.sliderCircular.thumbTintColor = [UIColor clearColor];
    else
        self.sliderCircular.thumbTintColor = [UIColor colorWithRed:0 green:0.89453125 blue:0.984375 alpha:1];
}

#pragma mark - Group Selection
- (UIColor *)getFanTextColor:(BOOL)bSelected
{
    if(bSelected)
        return [UIColor blueColor];
    return [UIColor grayColor];
}

- (void)selectFanSpeed:(NSInteger)index sendToDevice:(BOOL)send
{
    if(nil == self.btnLow)
        return;
    
    NSArray *btnItems = @[self.btnLow, self.btnMid, self.btnHigh];
    NSArray *textItems = @[self.textLow, self.textMid, self.textHigh];
    
    //风速：低，中，高，就只能选择其中的一种
    if(index >= -1 && index <= 2)
    {
        iFanSpeed = index;
        for(int i=0; i<MIN(btnItems.count, textItems.count); i++)
        {
            BOOL bSelected = (index == i);
            ((UIButton *)btnItems[i]).selected = bSelected;
            ((UILabel *)textItems[i]).textColor = [self getFanTextColor:bSelected];
        }
        
        //发送数据
        if(send && index != -1)
            [self writeDataPoint:IoTDeviceWriteFanSpeed value:@(iFanSpeed)];
    }
}

- (void)selectFanSwing:(BOOL)bSelected sendToDevice:(BOOL)send
{
    bFanSwing = bSelected;
    
    //发送数据
    if(send)
        [self writeDataPoint:IoTDeviceWriteFanSwing value:@(bSelected)];
    
    self.btnShake.selected = bSelected;
    self.textShake.textColor = [self getFanTextColor:bSelected];
}

- (void)selectMode:(NSInteger)index sendToDevice:(BOOL)send
{
    if(index >= 0 && index <= (AIRCONDITION_MODE_COUNT-1))
    {
        iMode = index;
        
        //发送数据
        if(send)
            [self writeDataPoint:IoTDeviceWriteMode value:@(index)];
        
        //0.制冷, 1.送风, 2.除湿, 3.自动, 4.制热
        if(!modeImages)
            modeImages = @[[UIImage imageNamed:@"icon_model"],
                                [UIImage imageNamed:@"icon_model_05"],
                                [UIImage imageNamed:@"icon_model_03"],
                                [UIImage imageNamed:@"icon_model_04"],
                                [UIImage imageNamed:@"icon_model_02"]];
        if(!modeTexts)
            modeTexts = @[@"制冷", @"送风", @"除湿", @"自动", @"制热"];
        
        self.imageMode.image = modeImages[index];
        self.textMode.text = modeTexts[index];
    }
}

- (int)convertCTempToF:(int)ctemp {
    //摄氏度×9/5+32=华氏度
    return ctemp*9/5+32;
}

#pragma mark - Actions
- (void)onDisconnected {
    if(!self.device.isConnected)
    {
        [IoTAppDelegate.hud hide:YES];
        [_alertView hide:YES];
        [[[IoTAlertView alloc] initWithMessage:@"连接已断开" delegate:nil titleOK:@"确定"] show:YES];
    }
    
    //退出到列表
    for(int i=(int)(self.navigationController.viewControllers.count-1); i>0; i--)
    {
        UIViewController *controller = self.navigationController.viewControllers[i];
        if([controller isKindOfClass:[IoTDeviceList class]])
        {
            [self.navigationController popToViewController:controller animated:YES];
        }
    }
}

- (void)onUpdateAlarm {
    //自定义标题
    CGRect rc = CGRectMake(0, 0, 200, 64);
    
    UILabel *label = [[UILabel alloc] initWithFrame:rc];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"移动空调";
    label.font = [UIFont boldSystemFontOfSize:label.font.pointSize];
    
    UIButton *view = [UIButton buttonWithType:UIButtonTypeCustom];
    [view addTarget:self action:@selector(onAlarmList) forControlEvents:UIControlEventTouchUpInside];
    view.frame = rc;
    [view addSubview:label];
    
    //故障条目数，原则上不大于65535
    NSInteger count = [IoTRecord sharedInstance].recordedCount;
    if(count > 65535)
        count = 65535;
    
    if(count > 0)
    {
        double n = log10(count);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(140, 23, 22+n*8, 18)];
        imageView.image = [[UIImage imageNamed:@"fault_tips.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:0];
        [view addSubview:imageView];
        
        UILabel *labelBadge = [[UILabel alloc] initWithFrame:imageView.bounds];
        labelBadge.textColor = [UIColor colorWithRed:0.1484375 green:0.49609375 blue:0.90234375 alpha:1.00];
        labelBadge.textAlignment = NSTextAlignmentCenter;
        labelBadge.text = [NSString stringWithFormat:@"%@", @(count)];
        [imageView addSubview:labelBadge];
        
        //弹出报警提示
        [_alertView hide:YES];
        _alertView = [[IoTAlertView alloc] initWithMessage:@"设备故障" delegate:self titleOK:@"暂不处理" titleCancel:@"拨打客服"];
        [_alertView show:YES];
    }
    
    self.navigationItem.titleView = view;
}

- (void)onAlarmList {
    IoTFaultList *faultList = [[IoTFaultList alloc] init];
    [self.navigationController pushViewController:faultList animated:YES];
}

- (void)onPower {
    //不在线就不能点
    if(!self.device.isOnline)
        return;
    
    if(bSwitch)
    {
        //关机
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"是否确定关机？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        alertView.tag = ALERT_TAG_SHUTDOWN;
        [alertView show];
    }
    else
    {
        //开机
        if(self.navigationController.viewControllers.lastObject == self)
        {
            IoTShutdownStatus *shutdownStatusCtrl = [[IoTShutdownStatus alloc] init];
            shutdownStatusCtrl.mainCtrl = self;
            
            [self.navigationController pushViewController:shutdownStatusCtrl animated:YES];
        }
    }
}

//============模式===========
- (IBAction)onModeMinute:(id)sender {
    if(iMode > 0)
    {
        iMode--;
        [self selectMode:iMode sendToDevice:YES];
    }
}

- (IBAction)onModeAdd:(id)sender {
    if(iMode < (AIRCONDITION_MODE_COUNT-1))
    {
        iMode++;
        [self selectMode:iMode sendToDevice:YES];
    }
}

//============风速===========
- (IBAction)onLow:(id)sender {
    if(iFanSpeed != 0)
        [self selectFanSpeed:0 sendToDevice:YES];
}

- (IBAction)onMid:(id)sender {
    if(iFanSpeed != 1)
        [self selectFanSpeed:1 sendToDevice:YES];
}

- (IBAction)onHigh:(id)sender {
    if(iFanSpeed != 2)
        [self selectFanSpeed:2 sendToDevice:YES];
}

- (IBAction)onShake:(UIButton *)sender {
    [self selectFanSwing:!bFanSwing sendToDevice:YES];
}

- (void)onUpdateTemp:(BOOL)updateSlider {
    int roomTemp = (int)iTemp;
    int setTemp = (int)iSetTemp;
    
    if(!updateSlider)
        setTemp = self.sliderCircular.value;
    
    //如果是华氏度？
    if(self.btnTempUnit.selected)
    {
        roomTemp = [self convertCTempToF:roomTemp];
        setTemp = [self convertCTempToF:setTemp];
        self.textUnit1.text = @"℉";
        self.textUnit2.text = self.textUnit1.text;
    }
    else
    {
        self.textUnit1.text = @"℃";
        self.textUnit2.text = self.textUnit1.text;
    }
    
    if(updateSlider)
        self.sliderCircular.value = iSetTemp;
    self.textCurrentTemp.text = [NSString stringWithFormat:@"%@", @(roomTemp)];
    self.textSetupTemp.text = [NSString stringWithFormat:@"%@", @(setTemp)];
}
//==

//===========工具条===========
- (IBAction)onTimeShut:(id)sender {
    [_timingSelection hide:YES];
    _timingSelection = [[IoTTimingSelection alloc] initWithTitle:@"定时关机" delegate:self currentValue:iOffTiming==0?24:(iOffTiming-1)];
    [_timingSelection show:YES];
}

- (IBAction)onSettings:(id)sender {
    CGRect frame = self.globalView.frame;
    if(frame.origin.y == 0)
        frame.origin.y = -100;
    else
        frame.origin.y = 0;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:YES];
    self.globalView.frame = frame;
    [UIView commitAnimations];
}
//==

//=======高级设置中的选项========
- (IBAction)onTempGraphics:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"提示" message:@"功能尚未开放，敬请期待" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
}

- (IBAction)onSwitchTempUnit:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self onUpdateTemp:YES];
}
//==

//===========圆圈控件===========
- (void)onUpdateProgress:(UICircularSlider *)slider{
    [self onUpdateTemp:NO];
}

- (void)onSliderTouchedUpInside:(UICircularSlider *)slider{
    [self onUpdateTemp:NO];
    iSetTemp = ((int)slider.value);
    [self writeDataPoint:IoTDeviceWriteTemperature value:@(iSetTemp)];
}

- (void)onUpdateShutdownText {
    if(iOffTiming == 0)
        self.textShutdown.text = @"定时关机";
    else
        self.textShutdown.text = [NSString stringWithFormat:@"%@小时后关机", @(iOffTiming)];
}

//==

#pragma mark - Properties
- (NSInteger)onTiming
{
    return iOnTiming;
}

- (void)setOnTiming:(NSInteger)onTiming
{
    iOnTiming = onTiming;
}

- (void)setDevice:(XPGWifiDevice *)device
{
    _device.delegate = nil;
    _device = device;
    [self initDevice];
}

#pragma mark - Key value observe
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //防止这个值被恶意修改
    if(self.view.userInteractionEnabled != bSwitch)
        self.view.userInteractionEnabled = bSwitch;
}

#pragma mark - XPGWifiDeviceDelegate
- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device
{
    if(![device.did isEqualToString:self.device.did])
        return;

    [self onDisconnected];
}

- (BOOL)XPGWifiDevice:(XPGWifiDevice *)device didReceiveData:(NSDictionary *)data result:(int)result
{
    if(![device.did isEqualToString:self.device.did])
        return YES;
    
    [IoTAppDelegate.hud hide:YES];
    
    /**
     * 数据部分
     */
    NSDictionary *_data = [data valueForKey:@"data"];
    
    if(nil != _data)
    {
        NSString *onOff = [self readDataPoint:IoTDeviceWriteOnOff data:_data];
        NSString *fanSwing = [self readDataPoint:IoTDeviceWriteFanSwing data:_data];
        NSString *mode = [self readDataPoint:IoTDeviceWriteMode data:_data];
        NSString *fanSpeed = [self readDataPoint:IoTDeviceWriteFanSpeed data:_data];
        NSString *onTiming = [self readDataPoint:IoTDeviceWriteOnTiming data:_data];
        NSString *offTiming = [self readDataPoint:IoTDeviceWriteOffTiming data:_data];
        NSString *setTemp = [self readDataPoint:IoTDeviceWriteTemperature data:_data];
        NSString *roomTemp = [self readDataPoint:IoTDeviceReadTemperature data:_data];
        
        bSwitch = [self prepareForUpdateInteger:onOff value:bSwitch];
        bFanSwing = [self prepareForUpdateInteger:fanSwing value:bFanSwing];
        iMode = [self prepareForUpdateFloat:mode value:iMode];
        iFanSpeed = [self prepareForUpdateFloat:fanSpeed value:iFanSpeed];
        self.onTiming = [self prepareForUpdateFloat:onTiming value:iOnTiming];
        iOffTiming = [self prepareForUpdateFloat:offTiming value:iOffTiming];
        iSetTemp = [self prepareForUpdateFloat:setTemp value:iSetTemp];
        iTemp = [self prepareForUpdateFloat:roomTemp value:iTemp];
        
        /**
         * 更新到 UI
         */
        [self selectFanSwing:bFanSwing sendToDevice:NO];
        [self selectFanSpeed:iFanSpeed sendToDevice:NO];
        [self selectMode:iMode sendToDevice:NO];
        [self onUpdateTemp:YES];
        self.view.userInteractionEnabled = bSwitch;
        
        //更新关机时间
        [self onUpdateShutdownText];
        
        //没有开机，切换页面
        if(!bSwitch)
        {
            [self onPower];
        }
        else
        {
            if([self.navigationController viewControllers].lastObject != self)
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }
    
    /**
     * 报警和错误
     */
    if([self.navigationController.viewControllers lastObject] != self)
        return YES;
    
    NSArray *alerts = [data valueForKey:@"alerts"];
    NSArray *faults = [data valueForKey:@"faults"];
    
    /**
     * 清理旧报警及故障
     */
    [[IoTRecord sharedInstance] clearAllRecord];
    
    if(alerts.count == 0 && faults.count == 0)
    {
        [self onUpdateAlarm];
        return YES;
    }
    
    //当前日期
    NSDate *date = [NSDate date];
    if(alerts.count > 0)
    {
        for(NSDictionary *dict in alerts)
        {
            for(NSString *name in dict.allKeys)
            {
                [[IoTRecord sharedInstance] addRecord:date information:name];
            }
        }
    }
    
    if(faults.count > 0)
    {
        for(NSDictionary *dict in faults)
        {
            for(NSString *name in dict.allKeys)
            {
                [[IoTRecord sharedInstance] addRecord:date information:name];
            }
        }
    }
    [self onUpdateAlarm];
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1 && buttonIndex == 0)
    {
        IoTAppDelegate.hud.labelText = @"正在关机...";
        [IoTAppDelegate.hud showAnimated:YES whileExecutingBlock:^{
            sleep(61);
        }];

        [self writeDataPoint:IoTDeviceWriteOnOff value:@0];
        [self writeDataPoint:IoTDeviceWriteOffTiming value:@0];
        [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
    }
}

- (void)IoTTimingSelectionDidConfirm:(IoTTimingSelection *)selection withValue:(NSInteger)value
{
    if(value == 24)
        iOffTiming = 0;
    else
        iOffTiming = value+1;
    [self writeDataPoint:IoTDeviceWriteOffTiming value:@(iOffTiming)];
    [self onUpdateShutdownText];
}

- (void)IoTAlertViewDidDismissButton:(IoTAlertView *)alertView withButton:(BOOL)isConfirm
{
    //拨打客服
    if(!isConfirm)
        [IoTAppDelegate callServices];
}

@end
