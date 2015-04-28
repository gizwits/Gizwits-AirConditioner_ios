/**
 * IoTMainController.h
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

#import <UIKit/UIKit.h>

typedef enum
{
    // writable
    IoTDeviceWriteUpdateData = 0,   //更新数据
    IoTDeviceWriteOnOff,            //开关
    IoTDeviceWriteFanSwing,         //摆风
    IoTDeviceWriteMode,             //模式
    IoTDeviceWriteFanSpeed,         //风速
    IoTDeviceWriteOnTiming,         //倒计时开机
    IoTDeviceWriteOffTiming,        //倒计时关机
    IoTDeviceWriteTemperature,      //温度设置
    
    // readonly
    IoTDeviceReadTemperature,       //温度
    
    // alarm
    IoTDeviceAlarmShutdown,         //停机报警
    IoTDeviceAlarmFull,             //水满报警
    
    // fault
    IoTDeviceFaultTemperature,      //室温故障
}IoTDeviceDataPoint;

typedef enum
{
    IoTDeviceCommandWrite    = 1,//写
    IoTDeviceCommandRead     = 2,//读
    IoTDeviceCommandResponse = 3,//读响应
    IoTDeviceCommandNotify   = 4,//通知
}IoTDeviceCommand;

#define DATA_CMD             @"cmd"       //命令
#define DATA_ENTITY          @"entity0"   //实体
#define DATA_ATTR_SWITCH     @"switch"    //属性：开关
#define DATA_ATTR_ON_TIMING  @"on_timing" //属性：倒计时开机
#define DATA_ATTR_OFF_TIMING @"off_timing"//属性：倒计时关机
#define DATA_ATTR_MODE       @"mode"      //属性：模式
#define DATA_ATTR_SET_TEMP   @"set_temp"  //属性：设置温度
#define DATA_ATTR_FAN_SPEED  @"fan_speed" //属性：风速
#define DATA_ATTR_FAN_SWING  @"fan_swing" //属性：摆风
#define DATA_ATTR_ROOM_TEMP  @"room_temp" //属性：温度

@interface IoTMainController : UIViewController<XPGWifiDeviceDelegate>

- (id)initWithDevice:(XPGWifiDevice *)device;

//写入数据接口
- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value;

//数据信息
@property (nonatomic, assign) NSInteger onTiming;       //开机定时

//用于切换设备
@property (nonatomic, strong) XPGWifiDevice *device;

@end
