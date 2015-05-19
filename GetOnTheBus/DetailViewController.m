
#import "DetailViewController.h"
#import <MapKit/MapKit.h>


@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UILabel *routesLabel;
@property (weak, nonatomic) IBOutlet UILabel *intermodalLabel;
@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nameLabel.text = [self.bus objectForKey:@"cta_stop_name"];
    self.routesLabel.text = [self.bus objectForKey:@"routes"];
    if ([self.bus objectForKey:@"inter_modal"] == nil || [[self.bus objectForKey:@"inter_modal"] isEqualToString:@""] ) {
        self.intermodalLabel.text = @"No Intermodal";
    }else{
        self.intermodalLabel.text = [self.bus objectForKey:@"inter_modal"];
    }
    
    CLLocationCoordinate2D coord;
    NSDictionary * locationDictionary =[self.bus objectForKey:@"location"];
    NSString *latitude =[locationDictionary objectForKey:@"latitude"];
    NSString *longitude= [locationDictionary objectForKey:@"longitude"];
    
    coord.latitude =[latitude doubleValue];
    coord.longitude =[longitude doubleValue];
    
    NSString *urlString =[NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?latlng=%@,%@&sensor=false", [NSString stringWithFormat:@"%f", coord.latitude ], [NSString stringWithFormat:@"%f", coord.longitude ]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [NSURLConnection sendAsynchronousRequest: request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSMutableDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        self.addressLabel.text = results[@"results"][1][@"formatted_address"];
        
    }];}

@end
