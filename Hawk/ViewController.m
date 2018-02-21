//
//  ViewController.m
//  Hawk
//
//  Created by Tobias Wittekindt on 02.02.18.
//  Copyright © 2018 Ottisoftware. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initVariables];
    [self setUI];
}

-(void)setUI {
    self.areaMapView.delegate = self;
    self.areaMapView.frame = self.view.frame;
    self.tapAreaMapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addMapPoint:)];
    [self.areaMapView addGestureRecognizer:self.tapAreaMapView];
    _addedMapPoints = 0;
    _addedPoints = [[NSMutableArray alloc] init];
    
}

-(void)initVariables {
    self.userLocation = kCLLocationCoordinate2DInvalid;
    [self startUpdateLocation];
    _editFlightPath = YES;
    _startFlightBO.enabled = NO;
    [_startFlightBO setBackgroundColor:[UIColor darkGrayColor]];
}

-(void)viewDidAppear:(BOOL)animated {
    [self performSelector:@selector(zoomMapView:) withObject:_areaMapView afterDelay:1];
    //[self zoomMapView:_areaMapView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark Location Methods
-(void) startUpdateLocation
{
    if ([CLLocationManager locationServicesEnabled]) {
        if (self.locationManager == nil) {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            self.locationManager.distanceFilter = 0.001;
            if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                [self.locationManager requestAlwaysAuthorization];
            }
            [self.locationManager startUpdatingLocation];
            
        }
    }else
    {
        NSLog(@"Location Service Disabled");
    }
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation* location = [locations lastObject];
    self.userLocation = location.coordinate;
}

- (void)addMapPoint:(UITapGestureRecognizer *)tapGesture
{
    
        if(_editFlightPath){
            CGPoint point = [tapGesture locationInView:self.areaMapView];
            if(tapGesture.state == UIGestureRecognizerStateEnded){
                [self addMapAnnotation:point withMapView:self.areaMapView];
            }
        } else {
            NSLog(@"EDIT FLIGHT PATH FALSE");
        }
    
}

- (void)addMapAnnotation:(CGPoint)point withMapView:(MKMapView *)mapView {
    CLLocationCoordinate2D coordinate = [mapView convertPoint:point toCoordinateFromView:mapView];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    //Keep track of all the added pins
    [_addedPoints addObject:location];
    
    //Show the Annotation
    MKPointAnnotation* annotation = [[MKPointAnnotation alloc] init];
    annotation.title = [NSString stringWithFormat:NSLocalizedString(@"Point", @"")];
    annotation.subtitle = NSLocalizedString(@"Defines the search area", @"");
    annotation.coordinate = location.coordinate;
    [mapView addAnnotation:annotation];
    _addedMapPoints += 1;
    
    [self createPolyline:mapView];
}
// Create a line that connects all Map Pins
-(void)createPolyline:(MKMapView *)mapView {
    MKGeodesicPolyline *geodesicPolyline;
    CLLocationCoordinate2D coordinateArray[(unsigned long)_addedPoints.count];
    _TotalDistance = 0;
    for(int i = 0; i < _addedPoints.count; i++){
        coordinateArray[i] = [[_addedPoints objectAtIndex:i] coordinate];
        
        if(i+1 < _addedPoints.count){
            CLLocation *from = [[CLLocation alloc] initWithLatitude:[[_addedPoints objectAtIndex:i] coordinate].latitude longitude:[[_addedPoints objectAtIndex:i] coordinate].longitude];
            CLLocation *to = [[CLLocation alloc] initWithLatitude:[[_addedPoints objectAtIndex:i+1] coordinate].latitude longitude:[[_addedPoints objectAtIndex:i+1] coordinate].longitude];
            
            _TotalDistance += [to distanceFromLocation:from];
        }
    }
    geodesicPolyline = [MKGeodesicPolyline polylineWithCoordinates:coordinateArray count:_addedMapPoints];
    [mapView removeOverlays:mapView.overlays];
    [mapView addOverlay:geodesicPolyline];
    _totalDistanceL.text = [NSString stringWithFormat:@"%0.fm", _TotalDistance];
    _TotalTime = (_TotalDistance/5)/60;
    _totalFlightTimeL.text = [NSString stringWithFormat:@"%0.fmin", _TotalTime];

}

// Create a polygon that connects all Map Pins
-(void)createPolygon:(MKMapView *)mapView {
    NSLog(@"Create Polygon");
    MKPolygon *polygon;
    CLLocationCoordinate2D coordinateArray[(unsigned long)_addedPoints.count];
    _TotalDistance = 0;
    for(int i = 0; i < _addedPoints.count; i++){
        coordinateArray[i] = [[_addedPoints objectAtIndex:i] coordinate];
    }
    polygon = [MKPolygon polygonWithCoordinates:coordinateArray count:[_addedPoints count]];
    [mapView addOverlay:polygon];
    
}



- (void)zoomMapView:(MKMapView *)mapView {
    if (CLLocationCoordinate2DIsValid(self.userLocation)) {
        MKCoordinateRegion region = {0};
        region.center = self.userLocation;
        region.span.latitudeDelta = 0.005;
        region.span.longitudeDelta = 0.005;
        [mapView setRegion:region animated:YES];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        NSLog(@"Normal pin");
        static NSString *defaultPinID = @"Pin_Annotation";
        MKAnnotationView *pinView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
        if ( pinView == nil ){
            pinView = [[MKAnnotationView alloc]
                       initWithAnnotation:annotation reuseIdentifier:defaultPinID];
        }
        pinView.canShowCallout = YES;
        pinView.draggable = YES;
        pinView.tag = _addedPoints.count;
        pinView.image =  [UIImage imageNamed:@"pin_select"];
        pinView.frame = CGRectMake(pinView.frame.origin.x-pinView.frame.size.width/4, pinView.frame.origin.y-pinView.frame.size.height/4, pinView.frame.size.width/2, pinView.frame.size.height/2);
        return pinView;
    }
    else if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    return nil;
    
}


- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if(_addedPoints.count > 2){
        NSUInteger index = view.tag;
        if(index == 1){
            NSLog(@"Finish");
            [self addMapAnnotation:view.center withMapView:self.areaMapView];
            _editFlightPath = NO;
            _startFlightBO.enabled = YES;
            [_startFlightBO setBackgroundColor:[UIColor colorWithRed:(30/255) green:(215/255) blue:(96/255) alpha:1.0]];
            [self createPolygon:_areaMapView];

        }
    }
    return;
}



- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    CLLocationCoordinate2D droppedAt = annotationView.annotation.coordinate;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:droppedAt.latitude longitude:droppedAt.longitude];
    NSInteger indexTag = annotationView.tag-1;
    NSTimer *dragTimer = nil;

    if (newState == MKAnnotationViewDragStateEnding)
    {
        NSLog(@"Dragging Ended");
        [dragTimer invalidate];
        [_addedPoints replaceObjectAtIndex:indexTag withObject:location];
        [self createPolyline:mapView];
    }
    if (newState == MKAnnotationViewDragStateStarting) {
        annotationView.dragState = MKAnnotationViewDragStateDragging;
    }
    else if (newState == MKAnnotationViewDragStateEnding || newState == MKAnnotationViewDragStateCanceling) {
        annotationView.dragState = MKAnnotationViewDragStateNone;
    }
    
    if(newState == MKAnnotationViewDragStateDragging){
        NSLog(@"DRAGGING...");
    }
}



- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id <MKOverlay>)overlay
{
    
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithOverlay:overlay];
        circleView.strokeColor = [UIColor colorWithRed:(0/255.0) green:(192/255.0) blue:(255/255.0) alpha:1];
        circleView.lineWidth = 3.0f;
        circleView.fillColor = [UIColor colorWithRed:(52/255.0) green:(152/255.0) blue:(220/255.0) alpha:0.5];
        
        circleView.alpha = 1;
        return circleView;
    }
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer *polygon = [[MKPolygonRenderer alloc] initWithOverlay:overlay];
        polygon.fillColor = [UIColor colorWithRed:(30/255) green:(215/255) blue:(96/255) alpha:0.15];
        return polygon;
    }
    // Offline Maps
    if([overlay isKindOfClass:[MKTileOverlay class]]) {
        MKTileOverlay *tileOverlay = (MKTileOverlay *)overlay;
        tileOverlay = nil;
        MKTileOverlayRenderer *renderer = nil;
        return renderer;
    }
    
    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer =
        [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline *)overlay];
        renderer.lineWidth = 3.0f;
        renderer.strokeColor = [UIColor colorWithRed:(52/255.0) green:(152/255.0) blue:(220/255.0) alpha:1];
        renderer.alpha = 0.75;
        return renderer;
    }

    return nil;
}


- (IBAction)clearFlightB:(id)sender {
    _addedPoints = [[NSMutableArray alloc] init];
    [_areaMapView removeOverlays:_areaMapView.overlays];
    [_areaMapView removeAnnotations:_areaMapView.annotations];
    _startFlightBO.enabled = NO;
    _addedMapPoints = 0;
    _editFlightPath = NO;
    _totalDistanceL.text = [NSString stringWithFormat:@"%0.fm", 0.0];
    _totalFlightTimeL.text = [NSString stringWithFormat:@"%0.fmin", 0.0];
 

}
- (IBAction)startFlightB:(id)sender {
    if(!_startFlight) {
        NSLog(@"Starting...");
        [UIView animateWithDuration:0.3 animations:^{
            [_startFlightBO setBackgroundColor:[UIColor redColor]];
        } completion:^(BOOL finished) {
            [_startFlightBO setTitle:@"STOP" forState:UIControlStateNormal];
        }];
        _startFlight = YES;
    } else {
        NSLog(@"Stop...");
        [UIView animateWithDuration:0.3 animations:^{
            [_startFlightBO setBackgroundColor:[UIColor colorWithRed:(30/255) green:(215/255) blue:(96/255) alpha:1.0]];
        } completion:^(BOOL finished) {
            [_startFlightBO setTitle:@"START" forState:UIControlStateNormal];
        }];
        _startFlight = NO;
    }
}
@end
