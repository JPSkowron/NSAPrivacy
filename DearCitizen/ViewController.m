//
//  ViewController.m
//  DearCitizen
//
//  Created by JP Skowron on 1/21/15.
//  Copyright (c) 2015 JP Skowron. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface ViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];

}
- (IBAction)startViolatingPrivacy:(id)sender {
    [self.locationManager startUpdatingLocation];
    self.textView.text = @"Locating you...";
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
}
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    for (CLLocation *location in locations) {
        if (location.horizontalAccuracy < 1000 && location.verticalAccuracy < 1000) {
            self.textView.text = @"Location found. Reserve geo-coding...";
            [self.locationManager stopUpdatingLocation];
            [self reverseGeocode: location];
            break;
        }
    }

}
-(void)reverseGeocode:(CLLocation *)location {
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks.firstObject;

        NSString *address ;
        if (placemark.subThoroughfare && placemark.thoroughfare) {
            address = [NSString stringWithFormat:@"%@ %@\n%@", placemark.subThoroughfare, placemark.thoroughfare, placemark.locality];
        }else{
            address = [[placemark.addressDictionary objectForKey:@"FormattedAddressLines"] componentsJoinedByString:@"\n"];
        }
        self.textView.text = address;

        [self findJailNear: placemark.location];
    }];
}

-(void)findJailNear:(CLLocation *)location {
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc]init];
    request.naturalLanguageQuery = @"Correctional";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(1, 1));

    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        NSArray *mapItems = response.mapItems;
        MKMapItem *mapItem = mapItems.firstObject;
        self.textView.text = [NSString stringWithFormat:@"You're a guilty SOB! Report to: %@", mapItem.name];
        [self getDirectionTo:mapItem];
    }];
}

-(void)getDirectionTo: (MKMapItem *)destination {
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc]init];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = destination;

    MKDirections *direction = [[MKDirections alloc] initWithRequest:request];
    [direction calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        NSArray *routes = response.routes;
        MKRoute *route = routes.firstObject;
        NSMutableString *instructions = [[NSMutableString alloc]init];
        for (MKRouteStep *step in route.steps) {
            NSLog(@"%@", step.instructions);
            [instructions appendFormat:@"%@\n", step.instructions];
        }
        self.textView.text = instructions;

        self.textView.text = [[response.routes.firstObject valueForKeyPath:@"steps.instructions"] componentsJoinedByString:@"\n"];
    }];
}

@end
