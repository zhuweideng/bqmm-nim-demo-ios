//
//  NIMSessionEmojiContentView.m
//  NIMKit
//
//  Created by isan on 10/10/2016.
//  Copyright © 2016 NetEase. All rights reserved.
//

#import "NIMSessionEmojiContentView.h"
#import "NIMMessageModel.h"
#import "UIView+NIM.h"
#import "NIMLoadProgressView.h"

//BQMM集成
#import <BQMM/BQMM.h>

@interface NIMSessionEmojiContentView()

@property (nonatomic,strong,readwrite) UIImageView * imageView;

@property (nonatomic,strong) NIMLoadProgressView * progressView;

@end

@implementation NIMSessionEmojiContentView

- (instancetype)initSessionMessageContentView{
    self = [super initSessionMessageContentView];
    if (self) {
        self.opaque = YES;
        _imageView  = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.backgroundColor = [UIColor clearColor];
        [self addSubview:_imageView];
        _progressView = [[NIMLoadProgressView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        _progressView.maxProgress = 1.0f;
        [self addSubview:_progressView];
        
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)data{
    [super refresh:data];
    self.bubbleImageView.hidden = YES;
    //BQMM集成
    self.imageView.image = [UIImage imageNamed:@"mm_emoji_loading"];
    NSDictionary *ext = data.message.remoteExt;
    if ([ext[@"txt_msgType"] isEqualToString:@"facetype"]) {
    
        NSArray *codes = nil;
        if (ext[@"msg_data"]) {
            codes = @[ext[@"msg_data"][0][0]];
        }
        __weak typeof(self) weakself = self;
        [[MMEmotionCentre defaultCentre] fetchEmojisByType:MMFetchTypeBig codes:codes completionHandler:^(NSArray *emojis) {
            if (emojis.count > 0) {
                MMEmoji *emoji = emojis[0];
                if ([codes[0] isEqualToString:emoji.emojiCode]) {
                    weakself.imageView.image = emoji.emojiImage; //TODO
                }
            }
            else {
                weakself.imageView.image = [UIImage imageNamed:@"mm_emoji_error"];
            }
        }];
    }
    self.progressView.hidden     = self.model.message.isOutgoingMsg ? (self.model.message.deliveryState != NIMMessageDeliveryStateDelivering) : (self.model.message.attachmentDownloadState != NIMMessageAttachmentDownloadStateDownloading);
    if (!self.progressView.hidden) {
        [self.progressView setProgress:[[[NIMSDK sharedSDK] chatManager] messageTransportProgress:self.model.message]];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    CGSize contentSize = self.model.contentSize;
    CGRect imageViewFrame = CGRectMake(contentInsets.left, contentInsets.top, contentSize.width, contentSize.height);
    self.imageView.frame  = imageViewFrame;
    _progressView.frame   = self.bounds;
    
    CALayer *maskLayer = [CALayer layer];
    maskLayer.cornerRadius = 13.0;
    maskLayer.backgroundColor = [UIColor blackColor].CGColor;
    maskLayer.frame = self.imageView.bounds;
    self.imageView.layer.mask = maskLayer;
}


- (void)onTouchUpInside:(id)sender
{
    NIMKitEvent *event = [[NIMKitEvent alloc] init];
    event.eventName = NIMKitEventNameTapContent;
    event.messageModel = self.model;
    [self.delegate onCatchEvent:event];
}

- (void)updateProgress:(float)progress
{
    if (progress > 1.0) {
        progress = 1.0;
    }
    self.progressView.progress = progress;
}

@end
