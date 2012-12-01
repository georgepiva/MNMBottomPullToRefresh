/*
 * Copyright (c) 2012 Mario Negro Martín
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */

#import "MNMBottomPullToRefreshManager.h"
#import "MNMBottomPullToRefreshView.h"

/**
 * Constants
 */
#define MNMBottomPullToRefreshManagerTableContentSizeKey    @"contentSize"

/**
 * Defines arrow image
 */
#define MNM_BOTTOM_PTR_ARROW_BOTTOM_IMAGE                               @"blueArrow.png"
#define TEXT_COLOR	 [UIColor colorWithRed:87.0/255.0 green:108.0/255.0 blue:137.0/255.0 alpha:1.0]

@interface MNMBottomPullToRefreshManager()

/**
 * Returns the correct offset to apply to the pull-to-refresh view, depending on contentSize
 *
 * @return The offset
 * @private
 */
- (CGFloat)tableScrollOffset;

/**
 * KVO methods
 */
- (void)registerAsObserver;
- (void)unregisterAsObserver;

@end

@implementation MNMBottomPullToRefreshManager

#pragma mark -
#pragma mark Memory management

/**
 * Deallocates not used memory
 */
- (void)dealloc {
    [self unregisterAsObserver];
    
    [pullToRefreshView_ release];
    pullToRefreshView_ = nil;
    
    [table_ release];
    table_ = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Instance initialization

/**
 * Implemented by subclasses to initialize a new object (the receiver) immediately after memory for it has been allocated.
 *
 * @return nil because that instance must be initialized with custom constructor
 */
- (id)init {
    return nil;
}

/*
 * Initializes the manager object with the information to link view and table
 */
- (id)initWithPullToRefreshViewHeight:(CGFloat)height tableView:(UITableView *)table withClient:(id<MNMBottomPullToRefreshManagerClient>)client {
    return [self initWithPullToRefreshViewHeight:height tableView:table withClient:client andOption:MNMBottomPullToRefreshViewOptionPullToRefresh];
}

/*
 * Initializes the manager object with the information to link view and table
 */
- (id)initWithPullToRefreshViewHeight:(CGFloat)height tableView:(UITableView *)table withClient:(id<MNMBottomPullToRefreshManagerClient>)client andOption:(MNMBottomPullToRefreshViewOptions)option {
    return [self initWithPullToRefreshViewHeight:height tableView:table arrowImageName:MNM_BOTTOM_PTR_ARROW_BOTTOM_IMAGE textColor:TEXT_COLOR backgroundColor:[UIColor clearColor] client:client andOption:option];
}

- (id)initWithPullToRefreshViewHeight:(CGFloat)height
                            tableView:(UITableView *)table
                       arrowImageName:(NSString *)arrowImageName
                            textColor:(UIColor *)textColor
                      backgroundColor:(UIColor *)backgroundColor
                               client:(id<MNMBottomPullToRefreshManagerClient>)client
                            andOption:(MNMBottomPullToRefreshViewOptions)option {
    
    if (self = [super init]) {
        
        client_ = client;
        
        table_ = [table retain];
        
        pullToRefreshView_ = [[MNMBottomPullToRefreshView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(table_.frame), height)
                                                                arrowImageName:arrowImageName
                                                                     textColor:textColor
                                                               backgroundColor:backgroundColor
                                                                     andOption:option];
        
        originalInsets_ = [table contentInset];
        
        UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 0.0f, 0.0f)];
        
        [table_ setTableFooterView:tableFooterView];
        
        [tableFooterView release];
        
        [self registerAsObserver];
    }
    
    return self;
}

#pragma mark -
#pragma mark KVO

/**
 * Register 'self' to receive change notifications for the "contentSize" property of
 * the 'tableView' object and specify the new value of "contentSize"
 * should be provided in the observe… method.
 */
- (void)registerAsObserver {
    [table_ addObserver:self
                     forKeyPath:MNMBottomPullToRefreshManagerTableContentSizeKey
                        options:NSKeyValueObservingOptionNew
                        context:NULL];
}

- (void)unregisterAsObserver {
    [table_ removeObserver:self forKeyPath:MNMBottomPullToRefreshManagerTableContentSizeKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqual:MNMBottomPullToRefreshManagerTableContentSizeKey]) {
        
        if ([self pullToRefreshViewIsOnScreen]) {
            
            [self relocatePullToRefreshView];
            
        }
    }
}

#pragma mark -
#pragma mark Visuals

/*
 * Returns the correct offset to apply to the pull-to-refresh view, depending on contentSize
 */
- (CGFloat)tableScrollOffset {
    
    CGFloat offset = 0.0f;        
    
    if (table_.contentSize.height < table_.frame.size.height) {
        
        offset = -table_.contentOffset.y;
        
    } else {
        
        offset = (table_.contentSize.height - table_.contentOffset.y) - table_.frame.size.height;
    }
    
    return offset;
}

/*
 * Relocate pull-to-refresh view
 */
- (void)relocatePullToRefreshView {
    
    CGFloat yCoord = 0.0f;
    
    if (table_.contentSize.height >= table_.frame.size.height) {
        
        yCoord = table_.contentSize.height;
        
    } else {
        
        yCoord = table_.frame.size.height;
    }
    
    CGRect frame = pullToRefreshView_.frame;
    frame.origin.y = yCoord;
    pullToRefreshView_.frame = frame;
    
    [table_ addSubview:pullToRefreshView_];
}

/*
 * Sets the pull-to-refresh view visible or not. Visible by default
 */
- (void)setPullToRefreshViewVisible:(BOOL)visible {
    pullToRefreshView_.hidden = !visible;
}

#pragma mark -
#pragma mark Table view scroll management

/**
 * Check if the pull-to-refresh view has an assigned superview
 */
- (BOOL)pullToRefreshViewIsOnScreen {
    return (Nil != [pullToRefreshView_ superview]);
}

/**
 * Remove pull-to-refresh view
 */
- (void)removePullToRefreshViewFromTableView {
    [pullToRefreshView_ removeFromSuperview];
}

/*
 * Checks state of control depending on tableView scroll offset
 */
- (void)tableViewScrolled {
    
    if (NO == [self pullToRefreshViewIsOnScreen])
        return;
    
    if (!pullToRefreshView_.hidden && !pullToRefreshView_.isLoading) {
        
        CGFloat offset = [self tableScrollOffset];
        CGFloat height = -CGRectGetHeight(pullToRefreshView_.frame);
        
        if (offset <= 0.0f && offset >= height) {
                
            [pullToRefreshView_ changeStateOfControl:MNMBottomPullToRefreshViewStatePull withOffset:offset];
            
        } else {
            
            [pullToRefreshView_ changeStateOfControl:MNMBottomPullToRefreshViewStateRelease withOffset:CGFLOAT_MAX];
        }
    }
}

/*
 * Checks releasing of the tableView
 */
- (void)tableViewReleased {
    
    if (NO == [self pullToRefreshViewIsOnScreen])
        return;
    
    if (!pullToRefreshView_.hidden && !pullToRefreshView_.isLoading) {
        
        CGFloat offset = [self tableScrollOffset];
        CGFloat height = -CGRectGetHeight(pullToRefreshView_.frame);
        
        if (offset <= 0.0f && offset < height) {
            
            [client_ MNMBottomPullToRefreshManagerClientReloadTable];
            
            [pullToRefreshView_ changeStateOfControl:MNMBottomPullToRefreshViewStateLoading withOffset:CGFLOAT_MAX];
            
            [UIView animateWithDuration:0.2f animations:^{
                
                if (table_.contentSize.height >= table_.frame.size.height) {
                
                    table_.contentInset = UIEdgeInsetsMake(originalInsets_.top, originalInsets_.left, -height - originalInsets_.bottom, originalInsets_.right);
                    
                } else {
                    
                    table_.contentInset = UIEdgeInsetsMake(height + originalInsets_.top, originalInsets_.left, originalInsets_.bottom, originalInsets_.right);
                }
            }];
        }
    }
}

/*
 * The reload of the table is completed
 */
- (void)tableViewReloadFinished {
    
    if ([self pullToRefreshViewIsOnScreen]) {
        [UIView animateWithDuration:0.2f animations:^{
            table_.contentInset = originalInsets_;
        }];
    }
        
    [pullToRefreshView_ changeStateOfControl:MNMBottomPullToRefreshViewStateIdle withOffset:CGFLOAT_MAX];
}

@end