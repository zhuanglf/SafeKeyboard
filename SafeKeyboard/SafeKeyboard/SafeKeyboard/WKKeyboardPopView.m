//
//  WKKeyboardPopView.m
//  SafeKeyboard
//
//  Created by ZhuangLifeng on 17/4/26.
//  Copyright © 2017年 庄黎峰. All rights reserved.
//

#import "WKKeyboardPopView.h"

#define IS_IPHONE6 ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 667 || [UIScreen mainScreen].bounds.size.width == 667)

#define IS_IPHONE6_PLUS ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 736 || [UIScreen mainScreen].bounds.size.width == 736)

#define AUTO_ADAPT_SIZE_VALUE(iPhone4_5, iPhone6, iPhone6plus) (IS_IPHONE6 ? iPhone6 : (IS_IPHONE6_PLUS ? iPhone6plus : iPhone4_5))

@interface WKKeyboardPopView()

@property (weak, nonatomic) IBOutlet UILabel *titleLetter;

@property (weak, nonatomic) IBOutlet UIImageView *backImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *letterCenterXConstraint;

@end

@implementation WKKeyboardPopView

+ (instancetype)popView
{
    return [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil].firstObject;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return NO;
}

- (void)showFromButton:(UIButton *)button
{
    if (button == nil) {
        return;
    }
    self.titleLetter.text = button.currentTitle;
    
    CGRect btnFrame = [button convertRect:button.bounds toView:nil];
    
    CGFloat popViewW = 80;
    CGFloat popViewH = AUTO_ADAPT_SIZE_VALUE(100, 108, 116);
    CGFloat popViewX = 0;
    CGFloat popViewY = btnFrame.origin.y - (popViewH - btnFrame.size.height);
    
    if (button.tag == 0 || [button.currentTitle isEqualToString:@"-"] || [button.currentTitle isEqualToString:@"["] || [button.currentTitle isEqualToString:@"_"]) {
        // 按钮在左边的情形
        self.backImageView.image = [UIImage imageNamed:@"keyboard_pop_left"];
        self.backImageView.image = [self.backImageView.image resizableImageWithCapInsets:UIEdgeInsetsMake(20, 10, 20, 50) resizingMode:UIImageResizingModeStretch];
        CGFloat cnt = btnFrame.size.width - 30;
        popViewW += cnt;
        popViewX = btnFrame.origin.x - AUTO_ADAPT_SIZE_VALUE(4, 4, 4);
        self.letterCenterXConstraint.constant = AUTO_ADAPT_SIZE_VALUE(-9, -11, -11);
    } else if (button.tag == 9 || [button.currentTitle isEqualToString:@"\""] || [button.currentTitle isEqualToString:@"="] || [button.currentTitle isEqualToString:@"•"]) {
        // 按钮在右边的情形
        self.backImageView.image = [UIImage imageNamed:@"keyboard_pop_right"];
        self.backImageView.image = [self.backImageView.image resizableImageWithCapInsets:UIEdgeInsetsMake(20, 50, 20, 10) resizingMode:UIImageResizingModeStretch];
        CGFloat cnt = btnFrame.size.width - 30;
        popViewW += cnt;
        popViewX = btnFrame.origin.x + btnFrame.size.width - (popViewW - 4);
        self.letterCenterXConstraint.constant = AUTO_ADAPT_SIZE_VALUE(9, 11, 11);
    } else {
        // 按钮在中间部分
        self.backImageView.image = [UIImage imageNamed:@"keyboard_pop"];
        self.backImageView.image = [self.backImageView.image resizableImageWithCapInsets:UIEdgeInsetsMake(20, 30, 20, 30) resizingMode:UIImageResizingModeStretch];
        CGFloat cnt = btnFrame.size.width - 30;
        popViewW += cnt;
        popViewX = btnFrame.origin.x - (popViewW - btnFrame.size.width) * 0.5;
        self.letterCenterXConstraint.constant = AUTO_ADAPT_SIZE_VALUE(0, 0, 0);
    }
    
    CGRect frame = CGRectMake(popViewX, popViewY, popViewW, popViewH);
    
    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    self.frame = frame;
    [window addSubview:self];
}

@end
