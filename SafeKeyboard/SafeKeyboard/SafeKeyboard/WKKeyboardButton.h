//
//  WKKeyboardButton.h
//  SafeKeyboard
//
//  Created by ZhuangLifeng on 17/4/26.
//  Copyright © 2017年 庄黎峰. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WKKeyboardButton : UIButton

- (void)shift:(BOOL)shift;

- (void)updateChar:(nullable NSString *)chars;

- (void)updateChar:(nullable NSString *)chars shift:(BOOL)shift;

@end
