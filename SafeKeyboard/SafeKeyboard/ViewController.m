//
//  ViewController.m
//  SafeKeyboard
//
//  Created by ZhuangLifeng on 17/4/26.
//  Copyright © 2017年 庄黎峰. All rights reserved.
//

#import "ViewController.h"
#import "WKSafeKeyboard.h"

@interface ViewController ()

@property (strong, nonatomic) UITextField *firstTextField;

@property (strong, nonatomic) UITextField *secondTextField;

@property (strong, nonatomic) UITextField *thirdTextField;

@property (strong, nonatomic) WKSafeKeyboard *safeKB;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.firstTextField];
    [self.view addSubview:self.secondTextField];
    [self.view addSubview:self.thirdTextField];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)kbWillShow:(NSNotification *)noti {
    //NSLog(@"%s--info:%@",__FUNCTION__,noti);
}

- (void)kbWillHide:(NSNotification *)noti {
    //NSLog(@"%s--info:%@",__FUNCTION__,noti);
}

- (UITextField *)firstTextField {
    if (!_firstTextField) {
        _firstTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 100, 200, 40)];
        _firstTextField.backgroundColor = [UIColor lightGrayColor];
        WKSafeKeyboard *kb = [WKSafeKeyboard keyboardWithType:WKSafeKeyboardTypeASCIICapable];
        _firstTextField.inputView = kb;
        kb.inputSource = _firstTextField;
        kb.needKeyboardSoundEffect = YES;
    }
    return _firstTextField;
}

- (UITextField *)secondTextField {
    if (!_secondTextField) {
        _secondTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 190, 200, 40)];
        _secondTextField.backgroundColor = [UIColor lightGrayColor];
        WKSafeKeyboard *kb = [WKSafeKeyboard keyboardWithType:WKSafeKeyboardTypeNumberPad];
        _secondTextField.inputView = kb;
        kb.inputSource = _secondTextField;
    }
    return _secondTextField;
}

- (UITextField *)thirdTextField {
    if (!_thirdTextField) {
        _thirdTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 280, 200, 40)];
        _thirdTextField.backgroundColor = [UIColor lightGrayColor];
        WKSafeKeyboard *kb = [WKSafeKeyboard keyboardWithType:WKSafeKeyboardTypeDecimalPad];
        _thirdTextField.inputView = kb;
        kb.inputSource = _thirdTextField;
        //        _thirdTextField.keyboardType = UIKeyboardTypeNumberPad;
    }
    return _thirdTextField;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.firstTextField resignFirstResponder];
    [self.secondTextField resignFirstResponder];
    [self.thirdTextField resignFirstResponder];
}

@end
