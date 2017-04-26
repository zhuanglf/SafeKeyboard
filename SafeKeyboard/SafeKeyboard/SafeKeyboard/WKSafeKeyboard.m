//
//  WKSafeKeyboard.m
//  SafeKeyboard
//
//  Created by ZhuangLifeng on 17/4/26.
//  Copyright © 2017年 庄黎峰. All rights reserved.
//

#import "WKSafeKeyboard.h"
#import "WKKeyboardPopView.h"
#import "WKKeyboardButton.h"
#import "UIImage+Extension.h"
#import <AVFoundation/AVFoundation.h>

#define WKKBH                       216
#define WKCHAR_CORNER               6
#define WKKBFontSize                18
#define WKKBFont(s)                 [UIFont fontWithName:@"HelveticaNeue-Light" size:s]
#define WKSCREEN_WIDTH              [UIScreen mainScreen].bounds.size.width
#define WKColor(r, g, b, a)         [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#define Characters [self createRandomCharacters]
#define Symbols    [self createRandomSymbols]
#define moreSymbols  @[@"[",@"]",@"{",@"}",@"#",@"%",@"^",@"*",@"+",@"=",@"_",@"\\",@"|",@"~",@"<",@">",@"€",@"£",@"¥",@"•",@".",@",",@"?",@"!",@"'"]

@interface WKSafeKeyboard ()

@property (nonatomic, assign) WKSafeKeyboardType type;
//是否shift
@property (nonatomic, assign) BOOL shiftEnable;
//是否显示字符
@property (nonatomic, assign) BOOL showSymbol;
//是否显示更多字符
@property (nonatomic, assign) BOOL showMoreSymbol;
//按键数组
@property (nonatomic, strong) NSMutableArray *charsBtn;
//shift按钮
@property (nonatomic, strong) UIButton *shiftBtn;
//删除按钮
@property (nonatomic ,strong) UIButton *deleteBtn;
//字符切换按钮
@property (nonatomic, strong) UIButton *charSymSwitch;
//空格按钮
@property (nonatomic, strong) UIButton *spaceBtn;
//确认按钮
@property (nonatomic, strong) UIButton *doneBtn;
//气泡效果
@property (nonatomic, strong) WKKeyboardPopView *popView;
//键盘音效
@property (nonatomic, assign) SystemSoundID soundID;
//是否旋转屏幕
@property (nonatomic, assign) BOOL isRotateScreen;
//保存字母符号数组
@property (nonatomic, strong) NSArray *lastASCIIArray;
//保存数字数组
@property (nonatomic, strong) NSArray *lastNumberArray;

@end

@implementation WKSafeKeyboard

+ (nullable)keyboardWithType:(WKSafeKeyboardType)type {
    return [[WKSafeKeyboard alloc] initWithFrame:CGRectMake(0, 0, WKSCREEN_WIDTH, WKKBH) withType:type];
}

- (id)initWithFrame:(CGRect)frame withType:(WKSafeKeyboardType)type {
    self = [super initWithFrame:frame];
    if (self) {
        self.type = type;
        [self initSetup];
        [self receiveNotification];
        self.isRotateScreen = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.type = WKSafeKeyboardTypeNumberPad;
        [self initSetup];
    }
    return self;
}

- (void)initSetup {
    //创建键盘
    if (WKSafeKeyboardTypeNumberPad == self.type) {
        [self reloadNumberPad:false];
    }else if (WKSafeKeyboardTypeDecimalPad == self.type){
        [self reloadNumberPad:true];
    }else if (WKSafeKeyboardTypeASCIICapable == self.type){
        [self setupASCIICapableLayout:true];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    //NSLog(@"%s--%@",__FUNCTION__,newSuperview);
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    //NSLog(@"%s--%@",__FUNCTION__,newWindow);
    if (!newWindow && self.type == WKSafeKeyboardTypeASCIICapable) {
        NSArray *charSets;
        if (!self.showSymbol) {
            charSets = self.isRotateScreen? self.lastASCIIArray : Characters;
        }else{
            charSets = self.isRotateScreen? self.lastASCIIArray :self.showMoreSymbol? moreSymbols:Symbols;
        }
        self.lastASCIIArray = charSets;
        [self loadCharacters:charSets];
    } else if (!newWindow && self.type != WKSafeKeyboardTypeASCIICapable) {
        [self loadRandomNumber];
    }
}

- (UIButton *)keyboardButtonWithLocation:(CGPoint)location
{
    NSUInteger count = self.charsBtn.count;
    for (NSUInteger i = 0; i < count; i++) {
        UIButton *btn = self.charsBtn[i];
        if (CGRectContainsPoint(btn.frame, location)) {
            return btn;
        }
    }
    return nil;
}

- (void)playSoundEffect
{
    if (self.needKeyboardSoundEffect) {
        AudioServicesPlaySystemSound(self.soundID);
    }
}

- (void)dealloc {
    self.popView = nil;
    AudioServicesDisposeSystemSoundID(_soundID);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)receiveNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeKeyBoardOrientation) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}

- (void)changeKeyBoardOrientation {
    self.isRotateScreen = YES;
    if (WKSafeKeyboardTypeNumberPad == self.type) {
        [self reloadNumberPad:false];
    }else if (WKSafeKeyboardTypeDecimalPad == self.type){
        [self reloadNumberPad:true];
    }else if (WKSafeKeyboardTypeASCIICapable == self.type){
        [self setupASCIICapableLayout:false];
    }
    
}

#pragma mark - Lazyload
- (WKKeyboardPopView *)popView
{
    if (_popView == nil) {
        _popView = [WKKeyboardPopView popView];
    }
    return _popView;
}

- (SystemSoundID)soundID
{
    if (_soundID == 0) {
        NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"keyboard-click.aiff" withExtension:nil];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(soundURL), &_soundID);
    }
    return _soundID;
}

#pragma mark -- 数字键盘 --

- (void)reloadNumberPad:(BOOL)decimal {
    NSArray *subviews = self.subviews;
    [subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    if (self.type != WKSafeKeyboardTypeASCIICapable) {
        int cols = 3;
        int rows = 4;
        UIColor *lineColor = WKColor(0, 0, 0, 1);
        UIColor *titleColor = WKColor(0, 0, 0, 1);
        UIColor *bgColor = WKColor(255, 255, 255, 1);
        UIColor *bgHighlightColor = WKColor(209, 213, 218, 1);
        UIFont *titleFont = WKKBFont(WKKBFontSize);
        CGFloat itemH = WKKBH/rows;
        CGFloat itemW = WKSCREEN_WIDTH/cols;
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                btn.exclusiveTouch = true;
                btn.layer.borderWidth = 0.5;
                btn.layer.borderColor = lineColor.CGColor;
                btn.frame = CGRectMake(j*itemW, i*itemH, itemW, itemH);
                btn.titleLabel.font = titleFont;
                btn.titleLabel.textAlignment = NSTextAlignmentCenter;
                btn.titleLabel.textColor = titleColor;
                [btn setTitleColor:titleColor forState:UIControlStateNormal];
                [btn setBackgroundImage:[UIImage imageFromColor:bgColor] forState:UIControlStateNormal];
                [btn setBackgroundImage:[UIImage imageFromColor:bgHighlightColor] forState:UIControlStateHighlighted];
                [btn addTarget:self action:@selector(touchDownAction:) forControlEvents:UIControlEventTouchDown];
                [btn addTarget:self action:@selector(touchCancelAction:) forControlEvents:UIControlEventTouchDragOutside];
                SEL selector;
                
                if (i*(rows-1)+j == (rows*cols-2-1)) {
                    selector = decimal?@selector(numberOrDecimalAction:):@selector(doneAction:);
                }else if (i*(rows-1)+j == (rows*cols-1)){
                    selector = @selector(deleteAction:);
                }else if (i*(rows-1)+j == (rows*cols-1-1)){
                    selector = @selector(numberOrDecimalAction:);
                }else{
                    selector = @selector(numberOrDecimalAction:);
                }
                NSInteger tag = i*(rows-1)+j;
                [btn setTag:tag];
                [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:btn];
                
            }
        }
        
        [self loadRandomNumber];
    }
}

- (void)loadRandomNumber {
    BOOL decimal = (self.type == WKSafeKeyboardTypeDecimalPad);
    NSArray *titles = self.isRotateScreen ? self.lastNumberArray : [self generateRandomNumberWithDecimal:decimal];
    self.lastNumberArray = titles;
    self.isRotateScreen = NO;
    NSArray *subviews = self.subviews;
    [subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIButton class]]) {
            UIButton *tmp = (UIButton *)obj;
            NSInteger __tag = tmp.tag;
            NSString *title ;
            if (__tag == 9) {
                title = decimal?[titles objectAtIndex:__tag]:@"✓";
                
            }else if (__tag == 10) {
                title = [titles lastObject];
            }else if (__tag == 11){
                title = @"";
                [tmp setImage:[UIImage imageNamed:@"keyboard_back"] forState:UIControlStateNormal];
                //                [tmp setImage:[UIImage imageNamed:@""] forState:UIControlStateHighlighted];
                [tmp setBackgroundImage:[UIImage imageFromColor:WKColor(209, 213, 218, 1)] forState:UIControlStateNormal];
                [tmp setBackgroundImage:[UIImage imageFromColor:WKColor(255, 255, 255, 1)] forState:UIControlStateHighlighted];
            }else {
                title = [titles objectAtIndex:__tag];
            }
            [tmp setTitle:title forState:UIControlStateNormal];
            
            if ([tmp.titleLabel.text isEqualToString:@"✓"]) {
                [tmp setBackgroundImage:[UIImage imageFromColor:WKColor(209, 213, 218, 1)] forState:UIControlStateNormal];
                [tmp setBackgroundImage:[UIImage imageFromColor:WKColor(255, 255, 255, 1)] forState:UIControlStateHighlighted];
            }
        }
    }];
    
}

#pragma mark -- 数字键盘 Action --

- (void)touchDownAction:(UIButton *)btn {
    UIColor *touchColor = WKColor(43, 116, 224, 1);
    [btn setBackgroundColor:touchColor];
}

- (void)touchCancelAction:(UIButton *)btn {
    [btn setBackgroundColor:[UIColor clearColor]];
}

- (void)doneAction:(UIButton *)btn {
    [btn setBackgroundColor:[UIColor clearColor]];
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
                BOOL ret = [tmp.delegate textFieldShouldEndEditing:tmp];
                [tmp endEditing:ret];
            }else{
                [tmp resignFirstResponder];
            }
            
        }else if ([self.inputSource isKindOfClass:[UITextView class]]){
            UITextView *tmp = (UITextView *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
                BOOL ret = [tmp.delegate textViewShouldEndEditing:tmp];
                [tmp endEditing:ret];
            }else{
                [tmp resignFirstResponder];
            }
            
        }else if ([self.inputSource isKindOfClass:[UISearchBar class]]){
            UISearchBar *tmp = (UISearchBar *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(searchBarShouldEndEditing:)]) {
                BOOL ret = [tmp.delegate searchBarShouldEndEditing:tmp];
                [tmp endEditing:ret];
            }else{
                [tmp resignFirstResponder];
            }
        }
    }
}

- (void)deleteAction:(UIButton *)btn {
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            [tmp deleteBackward];
        }else if ([self.inputSource isKindOfClass:[UITextView class]]){
            UITextView *tmp = (UITextView *)self.inputSource;
            [tmp deleteBackward];
        }else if ([self.inputSource isKindOfClass:[UISearchBar class]]){
            UISearchBar *tmp = (UISearchBar *)self.inputSource;
            NSMutableString *info = [NSMutableString stringWithString:tmp.text];
            if (info.length > 0) {
                NSString *s = [info substringToIndex:info.length-1];
                [tmp setText:s];
            }
        }
    }
    [btn setBackgroundColor:[UIColor clearColor]];
}

- (void)numberOrDecimalAction:(UIButton *)btn {
    NSString *title = [btn titleLabel].text;
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate textField:tmp shouldChangeCharactersInRange:range replacementString:title];
                if (ret) {
                    [tmp insertText:title];
                }
            }else{
                [tmp insertText:title];
            }
            
        }else if ([self.inputSource isKindOfClass:[UITextView class]]){
            UITextView *tmp = (UITextView *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate textView:tmp shouldChangeTextInRange:range replacementText:title];
                if (ret) {
                    [tmp insertText:title];
                }
            }else{
                [tmp insertText:title];
            }
            
        }else if ([self.inputSource isKindOfClass:[UISearchBar class]]){
            UISearchBar *tmp = (UISearchBar *)self.inputSource;
            NSMutableString *info = [NSMutableString stringWithString:tmp.text];
            [info appendString:title];
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate searchBar:tmp shouldChangeTextInRange:range replacementText:title];
                if (ret) {
                    [tmp setText:[info copy]];
                }
            }else{
                [tmp setText:[info copy]];
            }
        }
    }
    [btn setBackgroundColor:[UIColor clearColor]];
}

// 选择一个n以下的随机整数
// 计算m, 2的幂略高于n, 然后采用 random() 模数m,
// 如果在n和m之间就扔掉随机数
// (更多单纯的方法, 比如采用random()模数n, 介绍一个偏置)
// 倾向范围内较小的数字
static int random_below(int n) {
    int m = 1;
    //计算比n更大的两个最小的幂
    do {
        m <<= 1;
    } while(m < n);
    
    int ret;
    do {
        ret = random() % m;
    } while(ret >= n);
    return ret;
}

static inline int random_int(int low, int high) {
    return (arc4random() % (high-low+1)) + low;
}

- (NSArray *)generateRandomNumberWithDecimal:(BOOL)decimal {
    NSMutableArray *tmp = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        NSString *c = [NSString stringWithFormat:@"%d",i];
        [tmp addObject:c];
    }
    if (decimal) {
        [tmp addObject:@"."];
    }
    int len = (int)[tmp count];
    int max = random_below(len);
    //    NSLog(@"max :%d",max);
    for (int i = 0; i < max; i++) {
        int t = random_int(0, len-1);
        int index = (t+max)%len;
        [tmp exchangeObjectAtIndex:t withObjectAtIndex:index];
    }
    return [tmp copy];
}

#pragma mark -- 密码键盘 --


//创建随机字母数组
- (NSArray *)createRandomCharacters {
    NSMutableArray *charSets = [NSMutableArray arrayWithObjects:@"q",@"w",@"e",@"r",@"t",@"y",@"u",@"i",@"o",@"p",@"a",@"s",@"d",@"f",@"g",@"h",@"j",@"k",@"l",@"z",@"x",@"c",@"v",@"b",@"n",@"m", nil];
    NSMutableArray *randomCharSet = [[NSMutableArray alloc] initWithCapacity:0];
    for (int i = 0; i < 26; i ++) {
        int cnt = arc4random()%charSets.count;
        [randomCharSet addObject:charSets[cnt]];
        [charSets removeObjectAtIndex:cnt];
    }
    
    return randomCharSet;
}

//随机数字的符号键盘
- (NSArray *)createRandomSymbols {
    NSMutableArray *countSets = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"0", nil];
    NSMutableArray *randomCountSets = [[NSMutableArray alloc] initWithCapacity:0];
    for (int i = 0; i < 10; i ++) {
        int cnt = arc4random()%countSets.count;
        [randomCountSets addObject:countSets[cnt]];
        [countSets removeObjectAtIndex:cnt];
    }
    NSArray *symbolsArray = @[@"-",@"/",@":",@";",@"(",@")",@"$",@"&",@"@",@"\"",@".",@",",@"?",@"!",@"'"];
    for (NSString *symbol in symbolsArray) {
        [randomCountSets addObject:symbol];
    }
    return randomCountSets;
}

//布局键盘
- (void)setupASCIICapableLayout:(BOOL)init {
    self.backgroundColor = WKColor(209, 213, 218, 1);
    if (!init) {
        //不是初始化创建 重新布局字母或字符界面
        NSArray *subviews = self.subviews;
        [subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[WKKeyboardButton class]]) {
                [obj removeFromSuperview];
            }
        }];
    }
    if (_charsBtn || _charsBtn.count) {
        [_charsBtn removeAllObjects];
        _charsBtn = nil;
    }
    _charsBtn = [NSMutableArray arrayWithCapacity:0];
    
    NSArray *charSets ;NSArray *rangs;
    if (!self.showSymbol) {
        charSets = self.isRotateScreen? self.lastASCIIArray : Characters;
        rangs = @[@10,@19,@26];
    }else{
        charSets = self.isRotateScreen? self.lastASCIIArray :self.showMoreSymbol? moreSymbols:Symbols;
        rangs = @[@10,@20,@25];
    }
    self.lastASCIIArray = charSets;
    self.isRotateScreen = NO;
    //第一排
    NSInteger loc = 0;
    NSInteger length = [[rangs objectAtIndex:0] integerValue];
    NSArray *chars = [charSets subarrayWithRange:NSMakeRange(loc, length)];
    NSInteger len = [chars count];
    CGFloat char_h_dis = 7;
    CGFloat char_v_dis = 13;
    CGFloat char_uper_dis = 10;
    CGFloat char_width = (WKSCREEN_WIDTH-char_h_dis*len)/len;
    CGFloat char_heigh = (WKKBH-char_uper_dis*2-char_v_dis*3)/4;
    UIFont *titleFont = WKKBFont(WKKBFontSize);
    UIColor *titleColor = WKColor(0, 0, 0, 1);
    UIColor *inputBgColor = WKColor(255, 255, 255, 1);
    UIImage *inputBgImg = [UIImage imageFromColor:inputBgColor];
    UIColor *functionBgColor = WKColor(172, 179, 188, 1);
    UIImage *functionBgImg = [UIImage imageFromColor:functionBgColor];
    CGFloat cur_y = char_uper_dis;
    
    int n = 0;
    UIImage *charbgImg = [inputBgImg drawRectWithRoundCorner:WKCHAR_CORNER toSize:CGSizeMake(char_width, char_heigh)];
    for (int i = 0 ; i < len; i ++) {
        WKKeyboardButton *btn = [WKKeyboardButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(char_h_dis*0.5+(char_width+char_h_dis)*i, cur_y, char_width, char_heigh);
        btn.exclusiveTouch = true;
        btn.userInteractionEnabled = false;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:charbgImg forState:UIControlStateNormal];
        [btn setTag:n+i];
        [self addSubview:btn];
        [self.charsBtn addObject:btn];
    }
    n+=len;
    
    //第二排
    cur_y += char_heigh+char_v_dis;
    loc = [[rangs objectAtIndex:0] integerValue];
    length = [[rangs objectAtIndex:1] integerValue];
    chars = [charSets subarrayWithRange:NSMakeRange(loc, length-loc)];
    len = [chars count];
    CGFloat start_x = (WKSCREEN_WIDTH-char_width*len-char_h_dis*(len-1))/2;
    for (int i = 0 ; i < len; i ++) {
        WKKeyboardButton *btn = [WKKeyboardButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(start_x+(char_width+char_h_dis)*i, cur_y, char_width, char_heigh);
        btn.exclusiveTouch = true;
        btn.userInteractionEnabled = false;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:charbgImg forState:UIControlStateNormal];
        [btn setTag:n+i];
        [self addSubview:btn];
        [self.charsBtn addObject:btn];
    }
    n+=len;
    
    //第三排
    cur_y += char_heigh+char_v_dis;
    loc = [[rangs objectAtIndex:1] integerValue];
    length = [[rangs objectAtIndex:2] integerValue];
    chars = [charSets subarrayWithRange:NSMakeRange(loc, length-loc)];
    len = [chars count];
    //    CGFloat shift_dis = char_h_dis*1.5;
    CGFloat shiftWidth = char_width*1.5;
    char_width = (WKSCREEN_WIDTH-char_h_dis*4-shiftWidth*2-char_h_dis*(len-1))/len;
    charbgImg = [inputBgImg drawRectWithRoundCorner:WKCHAR_CORNER toSize:CGSizeMake(char_width, char_heigh)];
    if (init) {
        //shift
        UIImage *roundImg = [functionBgImg drawRectWithRoundCorner:WKCHAR_CORNER toSize:CGSizeMake(shiftWidth, char_heigh)];
        roundImg = [roundImg resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        //        UIImage *shiftSelectImg = [inputBgImg drawRectWithRoundCorner:WKCHAR_CORNER toSize:CGSizeMake(shiftWidth, char_heigh)];
        self.shiftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.shiftBtn.exclusiveTouch = true;
        [self.shiftBtn setImage:self.shiftEnable?[UIImage imageNamed:@"keyboard_case_upper"]:[UIImage imageNamed:@"keyboard_case_lower"] forState:UIControlStateNormal];
        [self.shiftBtn setBackgroundImage:roundImg forState:  UIControlStateNormal];
        [self.shiftBtn addTarget:self action:@selector(shiftAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.shiftBtn];
        
        //delete
        self.deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.deleteBtn.exclusiveTouch = true;
        [self.deleteBtn setImage:[UIImage imageNamed:@"keyboard_back"] forState:UIControlStateNormal];
        [self.deleteBtn setBackgroundImage:roundImg forState:UIControlStateNormal];
        [self.deleteBtn addTarget:self action:@selector(charDeleteAction:) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(charDeleteAllAction:)];
        longPress.minimumPressDuration = 1.0;
        [self.deleteBtn addGestureRecognizer:longPress];
        [self addSubview:self.deleteBtn];
    }
    self.shiftBtn.frame = CGRectMake(char_h_dis*0.5, cur_y, shiftWidth, char_heigh);
    self.deleteBtn.frame = CGRectMake(WKSCREEN_WIDTH-char_h_dis*0.5-shiftWidth, cur_y, shiftWidth, char_heigh);
    
    for (int i = 0 ; i < len; i ++) {
        WKKeyboardButton *btn = [WKKeyboardButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(char_h_dis*2+shiftWidth+(char_width+char_h_dis)*i, cur_y, char_width, char_heigh);
        btn.exclusiveTouch = true;
        btn.userInteractionEnabled = false;
        btn.titleLabel.font = titleFont;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        btn.titleLabel.textColor = titleColor;
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn setBackgroundImage:charbgImg forState:UIControlStateNormal];
        [btn setTag:n+i];
        [self addSubview:btn];
        [self.charsBtn addObject:btn];
    }
    
    //第四排
    cur_y += char_heigh+char_v_dis;
    CGFloat numWidth = shiftWidth*2;
    CGFloat spaceWidth = (WKSCREEN_WIDTH-char_h_dis*3-numWidth*2);
    
    if (init) {
        //#+123
        UIImage *roundImg = [functionBgImg drawRectWithRoundCorner:WKCHAR_CORNER toSize:CGSizeMake(numWidth, char_heigh)];
        roundImg = [roundImg resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        self.charSymSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
        self.charSymSwitch.exclusiveTouch = true;
        self.charSymSwitch.titleLabel.font = titleFont;
        self.charSymSwitch.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.charSymSwitch.titleLabel.textColor = titleColor;
        [self.charSymSwitch setTitleColor:titleColor forState:UIControlStateNormal];
        [self.charSymSwitch setTitle:@"#+123" forState:UIControlStateNormal];
        [self.charSymSwitch setBackgroundImage:roundImg forState:UIControlStateNormal];
        [self.charSymSwitch addTarget:self action:@selector(charSymbolSwitch:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.charSymSwitch];
        
        //Done
        self.doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.doneBtn.exclusiveTouch = true;
        self.doneBtn.titleLabel.font = titleFont;
        self.doneBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.doneBtn.titleLabel.textColor = titleColor;
        [self.doneBtn setTitleColor:titleColor forState:UIControlStateNormal];
        [self.doneBtn setTitle:@"Done" forState:UIControlStateNormal];
        [self.doneBtn setBackgroundImage:roundImg forState:UIControlStateNormal];
        [self.doneBtn addTarget:self action:@selector(charDoneAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.doneBtn];
        
        //Space
        UIImage *spaceImg = [inputBgImg drawRectWithRoundCorner:WKCHAR_CORNER toSize:CGSizeMake(numWidth, char_heigh)];
        self.spaceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.spaceBtn.exclusiveTouch = true;
        self.spaceBtn.titleLabel.font = titleFont;
        self.spaceBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.spaceBtn.titleLabel.textColor = titleColor;
        [self.spaceBtn setTitleColor:titleColor forState:UIControlStateNormal];
        [self.spaceBtn setTitle:@"Space" forState:UIControlStateNormal];
        spaceImg = [spaceImg resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch];
        [self.spaceBtn setBackgroundImage:spaceImg forState:UIControlStateNormal];
        [self.spaceBtn addTarget:self action:@selector(charSpaceAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.spaceBtn];
    }
    self.charSymSwitch.frame = CGRectMake(char_h_dis*0.5, cur_y, numWidth, char_heigh);
    self.doneBtn.frame = CGRectMake(WKSCREEN_WIDTH-char_h_dis*0.5-numWidth, cur_y, numWidth, char_heigh);;
    self.spaceBtn.frame = CGRectMake(char_h_dis*1.5+numWidth, cur_y, spaceWidth, char_heigh);
    
    
    [self loadCharacters:charSets];
}

//加载键盘符号
- (void)loadCharacters:(NSArray *)array {
    
    NSInteger len = [array count];
    if (!array || len == 0) {
        return;
    }
    NSArray *subviews = self.subviews;
    [subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj && [obj isKindOfClass:[WKKeyboardButton class]]) {
            WKKeyboardButton *tmp = (WKKeyboardButton *)obj;
            NSInteger __tag = tmp.tag;
            //NSLog(@"__tag:%zd---index:%d",__tag,idx);
            if (__tag < len) {
                NSString *tmpTitle = [array objectAtIndex:__tag];
                //NSLog(@"char:%@",tmpTitle);
                if (self.showSymbol) {
                    [tmp updateChar:tmpTitle];
                }else{
                    [tmp updateChar:tmpTitle shift:self.shiftEnable];
                }
            }
        }
    }];
}

#pragma mark -- 字符键盘 Action --
//shift
- (void)shiftAction:(UIButton *)btn {
    if (self.showSymbol) {
        //正显示字符符号 无需切换大写
        self.showMoreSymbol = !self.showMoreSymbol;
        [self updateShiftBtnTitleState];
        NSArray *__symbols = self.showMoreSymbol?moreSymbols:Symbols;
        [self loadCharacters:__symbols];
    }else{
        self.shiftEnable = !self.shiftEnable;
        NSArray *subChars = [self subviews];
        [btn setImage:self.shiftEnable?[UIImage imageNamed:@"keyboard_case_upper"]:[UIImage imageNamed:@"keyboard_case_lower"] forState:UIControlStateNormal];
        [subChars enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[WKKeyboardButton class]]) {
                WKKeyboardButton *tmp = (WKKeyboardButton *)obj;
                [tmp shift:self.shiftEnable];
            }
        }];
    }
    
    [self playSoundEffect];
}
//字母 符号切换
- (void)charSymbolSwitch:(UIButton *)btn {
    self.showSymbol = !self.showSymbol;
    NSString *title = self.showSymbol?@"ABC":@"#+123";
    [self.charSymSwitch setTitle:title forState:UIControlStateNormal];
    [self updateShiftBtnTitleState];
    [self setupASCIICapableLayout:false];
    
    [self playSoundEffect];
}

- (void)updateShiftBtnTitleState {
    NSString *title ;
    UIImage *image;
    if (self.showSymbol) {
        title = self.showMoreSymbol?@"123":@"#+=";
        [self.shiftBtn setTitle:title forState:UIControlStateNormal];
        [self.shiftBtn setTitleColor:WKColor(0, 0, 0, 1) forState:UIControlStateNormal];
        [self.shiftBtn setImage:nil forState:UIControlStateNormal];
    }else{
        image = self.shiftEnable?[UIImage imageNamed:@"keyboard_case_upper"]:[UIImage imageNamed:@"keyboard_case_lower"];
        [self.shiftBtn setImage:image forState:UIControlStateNormal];
        [self.shiftBtn setTitle:nil forState:UIControlStateNormal];
        
    }
}

//输入按键
- (void)characterTouchAction:(WKKeyboardButton *)btn {
    NSString *title = [btn titleLabel].text;
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate textField:tmp shouldChangeCharactersInRange:range replacementString:title];
                if (ret) {
                    [tmp insertText:title];
                }
            }else{
                [tmp insertText:title];
            }
            
        }else if ([self.inputSource isKindOfClass:[UITextView class]]){
            UITextView *tmp = (UITextView *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate textView:tmp shouldChangeTextInRange:range replacementText:title];
                if (ret) {
                    [tmp insertText:title];
                }
            }else{
                [tmp insertText:title];
            }
            
        }else if ([self.inputSource isKindOfClass:[UISearchBar class]]){
            UISearchBar *tmp = (UISearchBar *)self.inputSource;
            NSMutableString *info = [NSMutableString stringWithString:tmp.text];
            [info appendString:title];
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate searchBar:tmp shouldChangeTextInRange:range replacementText:title];
                if (ret) {
                    [tmp setText:[info copy]];
                }
            }else{
                [tmp setText:[info copy]];
            }
        }
    }
}

//space
- (void)charSpaceAction:(UIButton *)btn {
    NSString *title = @" ";
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate textField:tmp shouldChangeCharactersInRange:range replacementString:title];
                if (ret) {
                    [tmp insertText:title];
                }
            }else{
                [tmp insertText:title];
            }
            
        }else if ([self.inputSource isKindOfClass:[UITextView class]]){
            UITextView *tmp = (UITextView *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate textView:tmp shouldChangeTextInRange:range replacementText:title];
                if (ret) {
                    [tmp insertText:title];
                }
            }else{
                [tmp insertText:title];
            }
            
        }else if ([self.inputSource isKindOfClass:[UISearchBar class]]){
            UISearchBar *tmp = (UISearchBar *)self.inputSource;
            NSMutableString *info = [NSMutableString stringWithString:tmp.text];
            [info appendString:title];
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)]) {
                NSRange range = NSMakeRange(tmp.text.length, 1);
                BOOL ret = [tmp.delegate searchBar:tmp shouldChangeTextInRange:range replacementText:title];
                if (ret) {
                    [tmp setText:[info copy]];
                }
            }else{
                [tmp setText:[info copy]];
            }
        }
    }
    
    [self playSoundEffect];
    
}

//删除
- (void)charDeleteAction:(UIButton *)btn {
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            [tmp deleteBackward];
        }else if ([self.inputSource isKindOfClass:[UITextView class]]){
            UITextView *tmp = (UITextView *)self.inputSource;
            [tmp deleteBackward];
        }else if ([self.inputSource isKindOfClass:[UISearchBar class]]){
            UISearchBar *tmp = (UISearchBar *)self.inputSource;
            NSMutableString *info = [NSMutableString stringWithString:tmp.text];
            if (info.length > 0) {
                NSString *s = [info substringToIndex:info.length-1];
                [tmp setText:s];
            }
        }
    }
    
    [self playSoundEffect];
    
}

//长按back清除
- (void)charDeleteAllAction:(UILongPressGestureRecognizer *)longPress {
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            tmp.text = @"";
        }else if ([self.inputSource isKindOfClass:[UITextView class]]){
            UITextView *tmp = (UITextView *)self.inputSource;
            tmp.text = @"";
        }else if ([self.inputSource isKindOfClass:[UISearchBar class]]){
            UISearchBar *tmp = (UISearchBar *)self.inputSource;
            tmp.text = @"";
        }
    }
}

- (void)charDoneAction:(UIButton *)btn {
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
                BOOL ret = [tmp.delegate textFieldShouldEndEditing:tmp];
                [tmp endEditing:ret];
            }else{
                [tmp resignFirstResponder];
            }
            
        }else if ([self.inputSource isKindOfClass:[UITextView class]]){
            UITextView *tmp = (UITextView *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
                BOOL ret = [tmp.delegate textViewShouldEndEditing:tmp];
                [tmp endEditing:ret];
            }else{
                [tmp resignFirstResponder];
            }
            
        }else if ([self.inputSource isKindOfClass:[UISearchBar class]]){
            UISearchBar *tmp = (UISearchBar *)self.inputSource;
            
            if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(searchBarShouldEndEditing:)]) {
                BOOL ret = [tmp.delegate searchBarShouldEndEditing:tmp];
                [tmp endEditing:ret];
            }else{
                [tmp resignFirstResponder];
            }
        }
    }
    
    [self playSoundEffect];
    
}

- (BOOL)resignFirstResponder {
    if (self.inputSource) {
        [self.inputSource resignFirstResponder];
    }
    return[super resignFirstResponder];
}

#pragma mark -- 键盘Pan --

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //NSLog(@"_%s_",__FUNCTION__);
    CGPoint touchPoint = [[touches anyObject] locationInView:self];
    for (WKKeyboardButton *tmp in self.charsBtn) {
        NSArray *subs = [tmp subviews];
        if (subs.count == 3) {
            [[subs lastObject] removeFromSuperview];
        }
        if (CGRectContainsPoint(tmp.frame, touchPoint)) {
            //            [tmp addPopup];
            [self.popView showFromButton:tmp];
            
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //NSLog(@"_%s_",__FUNCTION__);
    CGPoint touchPoint = [[touches anyObject] locationInView:self];
    for (WKKeyboardButton *tmp in self.charsBtn) {
        NSArray *subs = [tmp subviews];
        if (subs.count == 3) {
            [[subs lastObject] removeFromSuperview];
        }
        if (CGRectContainsPoint(tmp.frame, touchPoint)) {
            [self.popView showFromButton:tmp];
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //NSLog(@"_%s_",__FUNCTION__);
    CGPoint touchPoint = [[touches anyObject] locationInView:self];
    for (WKKeyboardButton *tmp in self.charsBtn) {
        NSArray *subs = [tmp subviews];
        if (subs.count == 3) {
            [[subs lastObject] removeFromSuperview];
        }
        if (CGRectContainsPoint(tmp.frame, touchPoint)) {
            [self characterTouchAction:tmp];
        }
    }
    [self.popView removeFromSuperview];
    
    UITouch *touch = touches.anyObject;
    CGPoint location = [touch locationInView:touch.view];
    UIButton *btn = [self keyboardButtonWithLocation:location];
    if (btn) {
        [self playSoundEffect];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //NSLog(@"_%s_",__FUNCTION__);
    for (WKKeyboardButton *tmp in self.charsBtn) {
        NSArray *subs = [tmp subviews];
        if (subs.count == 3) {
            [[subs lastObject] removeFromSuperview];
        }
    }
    [self.popView removeFromSuperview];
    
}

@end
