//
//  ViewController.m
//  AVDemo
//
//  Created by wiley on 2021/1/25.
//

#import "ViewController.h"

#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor redColor];
    
    av_log(NULL, AV_LOG_ERROR, "error");
}


@end
