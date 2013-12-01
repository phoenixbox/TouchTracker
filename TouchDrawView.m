//
//  TouchDrawView.m
//  TouchTracker
//
//  Created by Shane Rogers on 11/30/13.
//  Copyright (c) 2013 Shane Rogers. All rights reserved.
//

#import "TouchDrawView.h"
#import "Line.h"

@implementation TouchDrawView

-(id)initWithFrame:(CGRect)r
{
    self = [super initWithFrame:r];
    
    if (self){
        linesInProcess = [[NSMutableDictionary alloc]init];
        
        completeLines = [[NSMutableArray alloc]init];
        
        [self setBackgroundColor:[UIColor whiteColor]];
        
        [self setMultipleTouchEnabled:YES];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
        [self addGestureRecognizer:tapRecognizer];
    }
    return self;
}

-(void)tap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized tap");
    
    // If there is just a tap remove all lines in process so that the tap doestn result in a new line dot
    [linesInProcess removeAllObjects];
    
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 10.0);
    CGContextSetLineCap(context,kCGLineCapRound);
    
    // Draw complete lines in black
    [[UIColor blackColor]set];
    for (Line *line in completeLines){
        CGContextMoveToPoint(context, [line begin].x,[line begin].y);
        CGContextAddLineToPoint(context,[line end].x, [line end].y);
        CGContextStrokePath(context);
    }
    
    // Draw lines in process in red
    [[UIColor redColor]set];
    for(NSValue *v in linesInProcess){
        Line *line = [linesInProcess objectForKey:v];
        CGContextMoveToPoint(context, [line begin].x, [line begin].y);
        CGContextAddLineToPoint(context, [line end].x, [line end].y);
        CGContextStrokePath(context);
    }
}
-(void)clearAll
{
    // Clear the collections
    [linesInProcess removeAllObjects];
    [completeLines removeAllObjects];
    
    // Redraw
    [self setNeedsDisplay];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches){
        // Check for double tap - if it is then call clearAll
        if([t tapCount]>1){
            [self clearAll];
            return;
        }
        // Use the touch object as the key
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        
        // Create a line for the value
        CGPoint loc = [t locationInView:self];
        Line *newLine = [[Line alloc]init];
        [newLine setBegin:loc];
        [newLine setEnd:loc];
        
        // Put the pair in the dictionary
        [linesInProcess setObject:newLine forKey:key];
    }
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Update linesInProcess with moved touches
    for(UITouch *t in touches){
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        
        // Find the line for this touch
        Line *line = [linesInProcess objectForKey:key];
        
        // Update the line
        CGPoint loc = [t locationInView:self];
        [line setEnd:loc];
    }
    // Redraw
    [self setNeedsDisplay];
}
-(void)endTouches:(NSSet *)touches
{
    // Remove ending touches from dictionary
    for (UITouch *t in touches){
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        Line *line = [linesInProcess objectForKey:key];
        
        // If the interruption is a double tap - line will be nil so add it to the array?
        if (line){
            [completeLines addObject:line];
            [linesInProcess removeObjectForKey:key];
        }
    }
    // Redraw
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self endTouches:touches];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self endTouches:touches];
}
@end
