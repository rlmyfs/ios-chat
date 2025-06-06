//
//  FaceBoard.m
//
//  Created by blue on 12-9-26.
//  Copyright (c) 2012年 blue. All rights reserved.
//  Email - 360511404@qq.com
//  http://github.com/bluemood

#import "WFCUFaceBoard.h"

#import "WFCUStickerItem.h"
#import "YLImageView.h"
#import "YLGIFImage.h"
#import "WFCUFaceButton.h"
#import "WFCUConfigManager.h"
#import "WFCUImage.h"
#import "WFCUUtilities.h"

#define FACE_COUNT_ROW  4
#define FACE_COUNT_CLU  7
#define FACE_COUNT_PAGE ( FACE_COUNT_ROW * FACE_COUNT_CLU - 1)
#define FACE_ICON_SIZE  44

#define STICKER_COUNT_ROW  2
#define STICKER_COUNT_CLU  4
#define STICKER_COUNT_PAGE ( STICKER_COUNT_ROW * STICKER_COUNT_CLU)
#define STICKER_ICON_SIZE  80


@interface WFCUFaceBoard() <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>
@property(nonatomic, strong) NSArray *faceEmojiArray;
@property(nonatomic,strong)UIView *tabbarView;
@property(nonatomic,strong) UIButton *sendBtn;
@property(nonatomic, strong)UIPageControl *facePageControl;
@property(nonatomic, strong)UICollectionView *collectionView;

@property(nonatomic, strong)UICollectionView *tabView;

@property(nonatomic, strong)NSMutableDictionary<NSString *, WFCUStickerItem *> *stickers;
@property(nonatomic, assign)int selectedTableRow;
@end

#define EMOJ_TAB_HEIGHT 42
#define EMOJ_FACE_VIEW_HEIGHT 190
#define EMOJ_PAGE_CONTROL_HEIGHT 20

#define EMOJ_AREA_HEIGHT (EMOJ_TAB_HEIGHT + EMOJ_FACE_VIEW_HEIGHT + EMOJ_PAGE_CONTROL_HEIGHT)
@implementation WFCUFaceBoard{
    int width;
    int location;
}

@synthesize delegate;
+ (NSString *)getStickerCachePath {
    NSArray * LibraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [[LibraryPaths objectAtIndex:0] stringByAppendingFormat:@"/Caches/Patch/"];
}

+ (NSString *)getStickerBundleName {
    NSString * bundleName = @"Stickers.bundle";
    return bundleName;
}

+ (void)load {
    [WFCUFaceBoard initStickers];
}

+ (void)initStickers {
    NSString * bundleName = [WFCUFaceBoard getStickerBundleName];
    NSError * err = nil;
    NSFileManager * defaultManager = [NSFileManager defaultManager];
    
    
    NSString * cacheBundleDir = [WFCUFaceBoard getStickerCachePath];
    NSLog(@"缓存资源目录: %@", cacheBundleDir);
    
    
    if (![defaultManager fileExistsAtPath:cacheBundleDir]) {
        [defaultManager createDirectoryAtPath:cacheBundleDir withIntermediateDirectories:YES attributes:nil error: &err];
        
        if(err){
            NSLog(@"初始化目录出错:%@", err);
            return;
        }
    }
    NSString * defaultBundlePath = [[NSBundle bundleForClass:[self class]].resourcePath stringByAppendingPathComponent: bundleName];
    
    NSString * cacheBundlePath = [cacheBundleDir stringByAppendingPathComponent:bundleName];
    if (![defaultManager fileExistsAtPath:cacheBundlePath]) {
        [defaultManager copyItemAtPath: defaultBundlePath toPath:cacheBundlePath error: &err];
        if(err){
            NSLog(@"复制初始资源文件出错:%@", err);
        }
    } else {
        checkAndCopyFiles(defaultBundlePath, cacheBundlePath);
    }
}

// 检查并拷贝文件的函数
void checkAndCopyFiles(NSString *defaultBundlePath, NSString *cacheBundlePath) {
    // 创建文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 检查源目录是否存在
    BOOL isDir;
    if (![fileManager fileExistsAtPath:defaultBundlePath isDirectory:&isDir] || !isDir) {
        NSLog(@"源目录不存在: %@", defaultBundlePath);
        return;
    }
    
    // 创建目标目录（如果不存在）
    NSError *error;
    if (![fileManager fileExistsAtPath:cacheBundlePath]) {
        if (![fileManager createDirectoryAtPath:cacheBundlePath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"无法创建目标目录: %@，错误: %@", cacheBundlePath, error.localizedDescription);
            return;
        }
    }
    
    // 获取源目录下的所有内容（文件和子目录）
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:defaultBundlePath error:&error];
    if (error) {
        NSLog(@"读取源目录内容失败: %@，错误: %@", defaultBundlePath, error.localizedDescription);
        return;
    }
    
    // 遍历所有内容
    for (NSString *itemName in contents) {
        NSString *itemPath = [defaultBundlePath stringByAppendingPathComponent:itemName];
        NSString *destinationPath = [cacheBundlePath stringByAppendingPathComponent:itemName];
        
        // 检查是文件还是目录
        BOOL isItemDir;
        if ([fileManager fileExistsAtPath:itemPath isDirectory:&isItemDir]) {
            if (isItemDir) {
                // 如果是目录，递归处理
                checkAndCopyFiles(itemPath, destinationPath);
            } else {
                // 如果是文件，检查是否需要拷贝
                if (![fileManager fileExistsAtPath:destinationPath]) {
                    // 拷贝文件
                    if (![fileManager copyItemAtPath:itemPath toPath:destinationPath error:&error]) {
                        NSLog(@"拷贝文件失败: %@ 到 %@，错误: %@", itemPath, destinationPath, error.localizedDescription);
                    }
                }
            }
        }
    }
}

- (void)loadStickers {
    self.stickers = [[NSMutableDictionary alloc] init];
    
    NSString *stickerPath = [[WFCUFaceBoard getStickerCachePath] stringByAppendingPathComponent:[WFCUFaceBoard getStickerBundleName]];
    
    NSError * err = nil;
    NSFileManager * defaultManager = [NSFileManager defaultManager];
    NSArray *paths = [defaultManager contentsOfDirectoryAtPath:stickerPath error:&err];
    if (err != nil) {
        NSLog(@"error:%@", err);
        return;
    }
    
    for (NSString *file in paths) {
        BOOL isDir = false;
        NSString *absfile = [stickerPath stringByAppendingPathComponent:file];
        if ([defaultManager fileExistsAtPath:absfile isDirectory:&isDir]) {
            if (!isDir) {
                WFCUStickerItem *item = [[WFCUStickerItem alloc] init];
                item.key = file;
                item.tabIcon = absfile;
                item.stickerPaths = [[NSMutableArray alloc] init];
                NSString *name = [[file lastPathComponent] stringByDeletingPathExtension];
                NSString *stickerSubPath = [stickerPath stringByAppendingPathComponent:name];
                if ([defaultManager fileExistsAtPath:stickerSubPath isDirectory:&isDir]) {
                    if (isDir) {
                        NSArray *paths = [defaultManager contentsOfDirectoryAtPath:stickerSubPath error:&err];
                        if (err != nil) {
                            NSLog(@"error:%@", err);
                            return;
                        }
                        for (NSString *p in paths) {
                            NSString *stickerabsfile = [stickerSubPath stringByAppendingPathComponent:p];
                            if ([defaultManager fileExistsAtPath:stickerabsfile isDirectory:&isDir]) {
                                if (!isDir) {
                                    [item.stickerPaths addObject:stickerabsfile];
                                }
                            }
                        }
                    }
                }
                self.stickers[item.key] = item;
            } else {
                NSLog(@"is dir %@", absfile);
            }
        }
    }
}

- (id)init {
    width = [UIScreen mainScreen].bounds.size.width;
    self = [super initWithFrame:CGRectMake(0, 0, width, EMOJ_AREA_HEIGHT + [WFCUUtilities wf_safeDistanceBottom])];
    
    [self loadStickers];
    if (self) {

        self.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;

        NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
        NSString *bundlePath = [resourcePath stringByAppendingPathComponent:@"Emoj.plist"];
        
        self.faceEmojiArray = [[NSArray alloc]initWithContentsOfFile:bundlePath];

        [self addSubview:self.collectionView];

        //添加PageControl
        [self addSubview:self.facePageControl];
        
        _tabbarView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - EMOJ_TAB_HEIGHT - [WFCUUtilities wf_safeDistanceBottom], self.frame.size.width, EMOJ_TAB_HEIGHT)];
        [self addSubview:_tabbarView];
        
        _sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendBtn.tag = 333;
        _sendBtn.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        _sendBtn.frame = CGRectMake(self.frame.size.width - 52,5,52, 37);
        [_sendBtn setTitle:WFCString(@"Send") forState:UIControlStateNormal];
        [_sendBtn setTitleColor:[WFCUConfigManager globalManager].textColor forState:UIControlStateNormal];
        self.sendBtn.layer.borderWidth = 0.5f;
        self.sendBtn.layer.borderColor = HEXCOLOR(0xdbdbdd).CGColor;
        [_sendBtn addTarget:self action:@selector(sendBtnHandle:) forControlEvents:UIControlEventTouchUpInside];
        [_tabbarView addSubview:_sendBtn];
        
        [_tabbarView addSubview:self.tabView];
        
        [_collectionView reloadData];

        [self.tabView setAllowsMultipleSelection:NO];
        self.tabView.allowsSelection = YES;
        self.selectedTableRow = 0;
    }

    return self;
}

- (void)setSelectedTableRow:(int)selectedTableRow {
    _selectedTableRow = selectedTableRow;
    [self.tabView reloadData];
}

- (UICollectionView *)tabView {
    if (!_tabView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _tabView = [[UICollectionView alloc] initWithFrame:CGRectMake(0,5,self.frame.size.width - 52, 37) collectionViewLayout:layout];
        _tabView.delegate = self;
        _tabView.dataSource = self;
        _tabView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        _tabView.showsHorizontalScrollIndicator = NO;
        _tabView.userInteractionEnabled = YES;
        [_tabView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellId"];
    }
    return _tabView;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 10);
        CGRect frame = self.bounds;
        frame.size.height = EMOJ_FACE_VIEW_HEIGHT;
        _collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.decelerationRate = 90;
        _collectionView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        _collectionView.showsHorizontalScrollIndicator = NO;
        
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellId"];
    }
    return _collectionView;
}

- (UIPageControl *)facePageControl {
    if (!_facePageControl) {
        _facePageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(width/2-100, EMOJ_FACE_VIEW_HEIGHT, 200, EMOJ_PAGE_CONTROL_HEIGHT)];
        [_facePageControl addTarget:self
                            action:@selector(pageChange:)
                  forControlEvents:UIControlEventValueChanged];
        
        _facePageControl.pageIndicatorTintColor = [UIColor grayColor];
        _facePageControl.currentPageIndicatorTintColor = [UIColor blackColor];
        
        _facePageControl.numberOfPages = [self getPagesCount:0];
        [self.tabView selectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        [self.tabView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
        
        _facePageControl.currentPage = 0;
        if (@available(iOS 14.0, *)) {
            _facePageControl.backgroundStyle = UIPageControlBackgroundStyleProminent;
            _facePageControl.allowsContinuousInteraction = YES;
        }
    }
    return _facePageControl;
}

- (void)sendBtnHandle:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchSendEmoj)]) {
        [self.delegate didTouchSendEmoj];
    }
}

- (int)pagesOfIndexPath:(NSIndexPath *)item {
    int pages = 0;
    for (int i = 0; i < item.section; i++) {
        pages += [self collectionView:self.collectionView numberOfItemsInSection:i];
    }
    pages += item.row;
    return pages;
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView == self.collectionView) {
        NSArray<NSIndexPath *> *items = [_collectionView indexPathsForVisibleItems];
        if (items.count == 2) {
            int pages0 = [self pagesOfIndexPath:items[0]];
            int pages1 = [self pagesOfIndexPath:items[1]];
            
            UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
            CGFloat offset0 = pages0 * (self.collectionView.bounds.size.width + layout.minimumLineSpacing);
            CGFloat offset1 = pages1 * (self.collectionView.bounds.size.width + layout.minimumInteritemSpacing);
            
            NSIndexPath *selectedOne;
            if (ABS(offset0-targetContentOffset->x) > ABS(offset1 - targetContentOffset->x)) {
                targetContentOffset->x = offset1;
                selectedOne = items[1];
            } else {
                targetContentOffset->x = offset0;
                selectedOne = items[0];
            }
            
            if (items[1].section != items[0].section) {
                self.facePageControl.numberOfPages = [self getPagesCount:selectedOne.section];
                self.selectedTableRow = selectedOne.section;
            }
            
            [self.facePageControl setCurrentPage:selectedOne.row];
            [self.facePageControl updateCurrentPageDisplay];
        } else if(items.count == 1) {
            int pages0 = [self pagesOfIndexPath:items[0]];
            
            UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
            CGFloat offset0 = pages0 * (self.collectionView.bounds.size.width + layout.minimumLineSpacing);
            targetContentOffset->x = offset0;
        }
    }
}

- (void)pageChange:(id)sender {
    
}

- (void)faceButton:(id)sender {
    int i = (int)((WFCUFaceButton*)sender).buttonIndex;
    if ([delegate respondsToSelector:@selector(didTouchEmoj:)]) {
        [delegate didTouchEmoj:self.faceEmojiArray[i]];
    }
    
}

- (void)backFace{
    if ([delegate respondsToSelector:@selector(didTouchBackEmoj)]) {
        [delegate didTouchBackEmoj];
    }
}

- (NSInteger)getPagesCount:(NSInteger)section {
    if (section == 0) {
        int FACE_COUNT_ALL = (int)self.faceEmojiArray.count;
        int pages;
        if (FACE_COUNT_ALL > 0) {
            pages = (FACE_COUNT_ALL - 1)/(FACE_COUNT_ROW * FACE_COUNT_CLU -1) + 1;
        } else {
            pages = 0;
        }
        return pages;
    } else {
        return (self.stickers[[self.stickers.allKeys objectAtIndex:(section - 1)]].stickerPaths.count - 1) / STICKER_COUNT_PAGE + 1;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (collectionView == self.collectionView) {
        if (self.disableSticker) {
            return 1;
        }
        return self.stickers.allKeys.count + 1;
    } else {
        return 1;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.tabView) {
        NSIndexPath *minOne = [NSIndexPath indexPathForRow:0 inSection:indexPath.row];
        
        self.facePageControl.numberOfPages = [self getPagesCount:minOne.section];
        self.facePageControl.currentPage = 0;
        [_collectionView scrollToItemAtIndexPath:minOne atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        
        self.selectedTableRow = indexPath.row;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.collectionView) {
        return [self getPagesCount:section];
    } else {
        if (self.disableSticker) {
            return 1;
        }
        return self.stickers.allKeys.count + 1;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView) {
        return self.collectionView.bounds.size;
    } else {
        return CGSizeMake(45, 37);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellId" forIndexPath:indexPath];
    
    for (UIView *subView in [cell subviews]) {
        [subView removeFromSuperview];
    }
    
    if (collectionView == self.collectionView) {
        if (indexPath.section == 0) {
            int startPos = (int)indexPath.row * FACE_COUNT_PAGE;
            int endPos = (int)MIN(self.faceEmojiArray.count, startPos +  FACE_COUNT_PAGE);
            for (int i = startPos; i <= endPos; i++) {
                int cli = (i - startPos)/FACE_COUNT_CLU;
                int col = (i - startPos)%FACE_COUNT_CLU;
                
                CGFloat x = col * width/7;
                CGFloat y = cli * FACE_ICON_SIZE + 8;
                
                if ((cli == FACE_COUNT_ROW -1 && col == FACE_COUNT_CLU - 1) || i == self.faceEmojiArray.count) {
                    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
                    [back setImage:[WFCUImage imageNamed:@"del_emoji_normal"] forState:UIControlStateNormal];
                    [back setImage:[WFCUImage imageNamed:@"del_emoji_select"] forState:UIControlStateSelected];
                    [back addTarget:self action:@selector(backFace) forControlEvents:UIControlEventTouchUpInside];
                    
                    if (i == self.faceEmojiArray.count) {
                        x = (FACE_COUNT_CLU - 1) * width/7;
                        y = (FACE_COUNT_ROW - 1) * FACE_ICON_SIZE + 8;
                    }
                    back.frame = CGRectMake( x, y, width/7, FACE_ICON_SIZE);
                    
                    [cell addSubview:back];
                } else {
                    WFCUFaceButton *faceButton = [WFCUFaceButton buttonWithType:UIButtonTypeCustom];
                    faceButton.buttonIndex = i;
                    
                    [faceButton addTarget:self
                                   action:@selector(faceButton:)
                         forControlEvents:UIControlEventTouchUpInside];
                    
                    faceButton.frame = CGRectMake( x, y, width/7, FACE_ICON_SIZE);
                    
                    [faceButton setTitle:self.faceEmojiArray[i]
                                forState:UIControlStateNormal];
                    
                    [cell addSubview:faceButton];
                }
            }
        } else {
            NSArray *paths = self.stickers[self.stickers.allKeys[indexPath.section - 1]].stickerPaths;
            
            int startPos = (int)indexPath.row * STICKER_COUNT_PAGE;
            int endPos = (int)MIN(paths.count, startPos +  STICKER_COUNT_PAGE);
            for (int i = startPos; i < endPos; i++) {
                int cli = (i - startPos)/STICKER_COUNT_CLU;
                int col = (i - startPos)%STICKER_COUNT_CLU;
                
                CGFloat x = col * width/STICKER_COUNT_CLU;
                CGFloat y = cli * STICKER_ICON_SIZE + 8;
                
                UIImageView *imageView;
                if ([[paths[i] pathExtension] isEqualToString:@"gif"]) {
                    imageView = [[YLImageView alloc] initWithFrame:CGRectMake( x + 10, y, width/STICKER_COUNT_CLU - 20, STICKER_ICON_SIZE)];
                    imageView.image = [YLGIFImage imageWithContentsOfFile:paths[i]];
                } else {
                    imageView = [[UIImageView alloc] initWithFrame:CGRectMake( x + 10, y, width/STICKER_COUNT_CLU - 20, STICKER_ICON_SIZE)];
                    imageView.image = [UIImage imageWithContentsOfFile:paths[i]];
                }
                [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapSticker:)]];
                imageView.userInteractionEnabled = YES;
                long tag = indexPath.section;
                tag <<= 16;
                tag += i;
                imageView.tag = tag;
                
                [cell addSubview:imageView];
                
            }
        }
    } else {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(11, 7, 23, 23)];
        if (indexPath.row == self.selectedTableRow) {
            cell.backgroundColor = HEXCOLOR(0xa8a8a8);;
        } else {
            cell.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        }
        
        if (indexPath.row == 0) {
            iv.image = [WFCUImage imageNamed:@"emoji_btn_normal"];
        } else {
            iv.image = [UIImage imageWithContentsOfFile:self.stickers[self.stickers.allKeys[indexPath.row - 1]].tabIcon];
        }
        
        [cell addSubview:iv];
    }
    
    
    return cell;
}

- (void)onTapSticker:(UITapGestureRecognizer *)sender {
    UIView *view = sender.view;
    long tag = view.tag;
    long i = tag & 0xFFFF;
    long section = tag >> 16;
    NSString *selectSticker = self.stickers[self.stickers.allKeys[section - 1]].stickerPaths[i];
    if ([self.delegate respondsToSelector:@selector(didSelectedSticker:)]) {
        [self.delegate didSelectedSticker:selectSticker];
    }
}
@end
