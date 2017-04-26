//
//  UIImage+Extension.h
//  SafeKeyboardDemo
//
//  Created by ZhuangLifeng on 16/8/31.
//  Copyright © 2016年 庄黎峰. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Extension)

+ (UIImage *)imageFromColor:(UIColor *)color;

- (UIImage *)drawRectWithRoundCorner:(CGFloat)radius toSize:(CGSize)size;

@end
