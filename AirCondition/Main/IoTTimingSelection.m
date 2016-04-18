/**
 * IoTTimingSelection.m
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

#import "IoTTimingSelection.h"

@interface IoTTimingSelection () <UIPickerViewDataSource, UIPickerViewDelegate>
{
    __strong IoTTimingSelection *showingCtrl;
}

@property (weak, nonatomic) IBOutlet UILabel *textTitle;
@property (weak, nonatomic) IBOutlet UIPickerView *picker;

@property (strong, nonatomic) NSString *title;
@property (assign, nonatomic) NSInteger selectedIndex;
@property (assign, nonatomic) id <IoTTimingSelectionDelegate>delegate;

@end

@implementation IoTTimingSelection

- (id)initWithTitle:(NSString *)title delegate:(id <IoTTimingSelectionDelegate>)delegate  currentValue:(NSInteger)value
{
    self = [super init];
    if(self)
    {
        self.title = title;
        self.delegate = delegate;
        self.selectedIndex = value;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.textTitle.text = self.title;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onConfirm:(id)sender {
    if([self.delegate respondsToSelector:@selector(IoTTimingSelectionDidConfirm:withValue:)])
    {
        [self.delegate IoTTimingSelectionDidConfirm:self withValue:self.selectedIndex];
    }
    [self hide:YES];
}

- (IBAction)onCancel:(id)sender {
    [self hide:YES];
}

- (void)show:(BOOL)animated
{
    showingCtrl = self;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:animated];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [[UIApplication sharedApplication].keyWindow addSubview:self.view];
    [UIView commitAnimations];
    
    self.view.frame = [UIApplication sharedApplication].keyWindow.frame;
    [self.picker selectRow:self.selectedIndex inComponent:0 animated:YES];
}

- (void)hide:(BOOL)animated
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:animated];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [self.view removeFromSuperview];
    [UIView commitAnimations];
    
    showingCtrl = nil;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 25;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if(row == 24)
        return @"关闭";
    return [NSString stringWithFormat:@"%i", (int)(row+1)];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.selectedIndex = row;
}

@end
