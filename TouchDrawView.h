//
//  TouchDrawView.h
//  TouchTracker
//
//  Created by Shane Rogers on 11/30/13.
//  Copyright (c) 2013 Shane Rogers. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Line;

@interface TouchDrawView : UIView <UIGestureRecognizerDelegate>
{
    NSMutableDictionary *linesInProcess;
    NSMutableArray *completeLines;
    
    UIPanGestureRecognizer *moveRecognizer;
}
@property (nonatomic, weak) Line *selectedLine;

-(Line *)lineAtPoint:(CGPoint)p;

-(void)clearAll;
-(void)endTouches:(NSSet *)touches;
@end
