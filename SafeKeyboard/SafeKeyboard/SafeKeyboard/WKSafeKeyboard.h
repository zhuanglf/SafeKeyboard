//
//  WKSafeKeyboard.h
//  SafeKeyboard
//
//  Created by ZhuangLifeng on 17/4/26.
//  Copyright © 2017年 庄黎峰. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    WKSafeKeyboardTypeNumberPad = 1 << 0,
    WKSafeKeyboardTypeDecimalPad = 1 << 1,
    WKSafeKeyboardTypeASCIICapable = 1 << 2
}WKSafeKeyboardType;

@interface WKSafeKeyboard : UIView

//创建键盘
+ (nonnull instancetype)keyboardWithType:(WKSafeKeyboardType)type;

//such as UITextField,UITextView,UISearchBar
@property (nonatomic, nullable, strong) UIView *inputSource;

//是否需要开启键盘音效
@property (nonatomic, assign) BOOL needKeyboardSoundEffect;

@end
