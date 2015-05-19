
#import "MapviewController.h"
#import <MapKit/MapKit.h>
#import "DetailViewController.h"

@interface MapviewController () <MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSMutableArray *buses;
@property NSMutableArray *busesStop;
@property (weak, nonatomic) IBOutlet UITableView *busesTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedOption;
@end

@implementation MapviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.buses = [[NSMutableArray alloc] init];
    self.busesStop = [[NSMutableArray alloc] init];
    self.busesTableView.alpha = 0;
    [self loadInitialDataFromJson];
}
- (IBAction)onSegmentedPressed:(id)sender {
    if (self.segmentedOption.selectedSegmentIndex == 0) {
        self.mapView.alpha = 1;
        self.busesTableView.alpha = 0;
    }else{
        [self.busesTableView reloadData];
        self.mapView.alpha = 0;
        self.busesTableView.alpha = 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.buses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCellID" forIndexPath:indexPath];
    
    NSDictionary *bus = self.buses[indexPath.row];
    cell.textLabel.text = [bus objectForKey:@"cta_stop_name"];
    cell.detailTextLabel.text = [bus objectForKey:@"routes"];

    return cell;
}


- (void)loadInitialDataFromJson {
    NSURL *url = [NSURL URLWithString:@"https://s3.amazonaws.com/mobile-makers-lib/bus.json"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *objectAtKey =[jsonDictionary objectForKey:@"row"];
        for (id object in objectAtKey) {
            [self.buses addObject: object];
        }
        [self loadPinsToMap];
    }];
}

- (void) loadPinsToMap{
    for (id bus in self.buses) {
        CLLocationCoordinate2D coord;
        [self setLatitudeAndLongitude:bus coord_p:&coord];
        [self addAnnotation:coord bus:bus];
    }
    
    [self.mapView showAnnotations:self.busesStop animated:YES];
}

- (void)setLatitudeAndLongitude:(id)bus coord_p:(CLLocationCoordinate2D *)coord_p {
    
    NSDictionary *location = [bus objectForKey:@"location"];
    NSString *latitude = [location objectForKey:@"latitude"];
    NSString *longitude =[location objectForKey:@"longitude"];
    if ([longitude doubleValue] < 0) {
        coord_p->latitude = [latitude doubleValue] ;
        coord_p->longitude = [longitude doubleValue];
    }
}

- (void)addAnnotation:(CLLocationCoordinate2D)coord bus:(id)bus {
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
    annotation.coordinate = coord;
    annotation.title = [bus objectForKey:@"cta_stop_name"];
    annotation.subtitle = [NSString stringWithFormat:@"Routes: %@",[bus objectForKey:@"routes"]];
    [self.busesStop addObject:annotation];
    [self.mapView addAnnotation:annotation];
}

- (NSDictionary *)findBusStopByName: (NSString *)name {
    NSDictionary *busDictionary;
    for (id bus in self.buses) {
        if ([[bus objectForKey:@"cta_stop_name"] isEqualToString: name]) {
            busDictionary = bus;
            break;
        }
    }
    return busDictionary;
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    
    if (annotation == mapView.userLocation) {
        return nil;
    }
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MyPinID"];
    pin.canShowCallout = YES;
    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    NSDictionary *busDictionary;
    busDictionary = [self findBusStopByName: annotation.title];
    if ([busDictionary objectForKey:@"inter_modal"] != nil) {
        if ([[busDictionary objectForKey:@"inter_modal"] isEqualToString:@"Metra"]) {
            pin.image = [UIImage imageNamed:@"metra"];
        }else{
            pin.image = [UIImage imageNamed:@"pace"];
        }
    }
    return pin;
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    
    if ([(UIButton*)control buttonType] == UIButtonTypeDetailDisclosure) {
        [self performSegueWithIdentifier:@"DetailVC" sender:view];
    }
}

-(IBAction) prepareForSegue:(UIStoryboardSegue *)segue sender:(MKAnnotationView*)sender
{
    NSString *busStopName;
    if ([segue.identifier isEqualToString:@"DetailVC"]) {
        busStopName = sender.annotation.title;
    }else if ([segue.identifier isEqualToString:@"CellSegue"]){
        UITableViewCell *cell = (UITableViewCell*)sender;
        busStopName = cell.textLabel.text;
    }
    DetailViewController *vc = segue.destinationViewController;
    vc.bus = [self findBusStopByName:busStopName];

}


@end
