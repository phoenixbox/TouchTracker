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
@synthesize selectedLine;

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
        
        // Instantiate subclass
        UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
        // add the subclass UIRecognizer to the view
        [self addGestureRecognizer:pressRecognizer];
        // Assign the instance variable to an instance of pan gesture
        moveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(moveLine:)];
        [moveRecognizer setDelegate:self];
        [moveRecognizer setCancelsTouchesInView:NO];
        [self addGestureRecognizer:moveRecognizer];
    }
    return self;
}

-(void)moveLine:(UIPanGestureRecognizer *)gr
{
    // If we havent selected a line - dont do anything
    if(![self selectedLine]) return;
    
    // When the pan recognizer changes position
    if([gr state]==UIGestureRecognizerStateChanged){
        // How far has the pan moved
        CGPoint translation = [gr translationInView:self];
        
        // Add teh translation to the current begin and end points of the line
        CGPoint begin = [[self selectedLine] begin];
        CGPoint end = [[self selectedLine] end];
        begin.x += translation.x;
        begin.y += translation.y;
        end.x += translation.x;
        end.y += translation.y;
        
        // Set the new beginning and end points of the line
        [[self selectedLine] setBegin:begin];
        [[self selectedLine] setEnd:end];
        
        // Redraw the screen
        [self setNeedsDisplay];
        
        [gr setTranslation:CGPointZero inView:self];
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other
{
    if (gestureRecognizer == moveRecognizer)return YES;
    return NO;
}

-(void)longPress:(UIGestureRecognizer *)gr
{
    if([gr state]==UIGestureRecognizerStateBegan){
        // Remove the menu if it is visible
        [[UIMenuController sharedMenuController]setMenuVisible:NO animated:YES];
        
        CGPoint point = [gr locationInView:self];
        [self setSelectedLine:[self lineAtPoint:point]];
        
        if ([self selectedLine]){
            [linesInProcess removeAllObjects];
        } else if ([gr state]==UIGestureRecognizerStateEnded){
            [self setSelectedLine:nil];
        }
        [self setNeedsDisplay];
    }
}

-(void)tap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized tap");
    
    CGPoint point = [gr locationInView:self];
    [self setSelectedLine:[self lineAtPoint:point]];
    
    // If there is just a tap remove all lines in process so that the tap doestn result in a new line dot
    [linesInProcess removeAllObjects];
    
    if ([self selectedLine]){
        [self becomeFirstResponder];
        
        // Obtain the menu controller via singleton
        UIMenuController *menu = [UIMenuController sharedMenuController];
        
        // Create a new 'delete' UIMenuItem
        UIMenuItem *deleteItem = [[UIMenuItem alloc]initWithTitle:@"DELETE"
                                                           action:@selector(deleteLine:)];
        [menu setMenuItems:[NSArray arrayWithObject:deleteItem]];
        
        // Tell the menu where it shoudl come from and show it
        [menu setTargetRect:CGRectMake(point.x,point.y,2,2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    } else{
        // Hide the menu if no item is selected
        [[UIMenuController sharedMenuController]setMenuVisible:NO animated:YES];
    }
    
    [self setNeedsDisplay];
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)deleteLine:(id)sender
{
    // Remove the selected line from the list of completeLines
    [completeLines removeObject:[self selectedLine]];
    
    // Redraw everything
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
    
    // If self has a selected line, draw it green - using its own properties
    if ([self selectedLine]) {
        [[UIColor greenColor] set];
        CGContextMoveToPoint(context, [[self selectedLine] begin].x,
                             [[self selectedLine] begin].y);
        CGContextAddLineToPoint(context, [[self selectedLine] end].x,
                                [[self selectedLine] end].y);
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
-(Line *)lineAtPoint:(CGPoint)p
{
    // Find a line close to the touch point
    for (Line *l in completeLines){
        CGPoint start = [l begin];
        CGPoint end = [l end];
        
        // Approximate by checking a few points on the line
        for(float t = 0.0; t <= 1.0; t += 0.05){
            float x = start.x +t * (end.x - start.x);
            float y = start.y +t * (end.y - start.y);
            
            // If the tapped point is within 20 points, return the line
            if (hypot(x - p.x, y - p.y)<20.0){
                return l;
            }
        }
    }
    // If nothing is close enough to the tapped point, then we didnt select a line
    return nil;
}
@end
