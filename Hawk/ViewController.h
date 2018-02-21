//
//  ViewController.h
//  Hawk
//
//  Created by Tobias Wittekindt on 02.02.18.
//  Copyright © 2018 Ottisoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>

//Map View & Annotations
@property (weak, nonatomic) IBOutlet MKMapView *areaMapView;
@property (nonatomic) int addedMapPoints;
@property NSMutableArray *addedPoints;
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, assign) CLLocationCoordinate2D userLocation;

//Bools
@property bool editFlightPath;
@property bool startFlight;

//Floats
@property float TotalDistance;
@property float TotalTime;
//Gesture Recognizer
@property (nonatomic, strong) UITapGestureRecognizer *tapAreaMapView;

//Buttons
@property (weak, nonatomic) IBOutlet UIButton *clearFlightBO;
- (IBAction)clearFlightB:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *startFlightBO;
- (IBAction)startFlightB:(id)sender;

//Labels
@property (weak, nonatomic) IBOutlet UILabel *totalDistanceL;
@property (weak, nonatomic) IBOutlet UILabel *totalFlightTimeL;


@end

