//
//  TouchViewController.m
//  TouchTracker
//
//  Created by Shane Rogers on 11/30/13.
//  Copyright (c) 2013 Shane Rogers. All rights reserved.
//

#import "TouchViewController.h"
#import "TouchDrawView.h"

@implementation TouchViewController

-(void)loadView
{
    [self setView:[[TouchDrawView alloc]initWithFrame:CGRectZero]];
}

@end
