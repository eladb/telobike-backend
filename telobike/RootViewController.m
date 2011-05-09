//
//  RootViewController.m
//  telofun
//
//  Created by eladb on 4/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "RootViewController.h"
#import "JSON.h"
#import "StationTableViewCell.h"
#import "AppDelegate.h"
#import "StationList.h"
#import "MapViewController.h"
#import "NSDictionary+Station.h"

static const NSTimeInterval kMinimumAutorefreshInterval = 5 * 60; // 5 minutes

@interface RootViewController (Private)

- (void)sortStations;
- (BOOL)doesStation:(NSDictionary*)station containKeyword:(NSString*)keyword;
- (BOOL)filterStation:(NSDictionary*)station;

// navigation bar icon handlers
- (void)refreshStations:(id)sender;
- (void)about:(id)sender;

@end

@implementation RootViewController

@synthesize tableView=_tableView;

- (void)dealloc
{
    [_tableView release];
    [mapView release];
    [locationManager release];
    [stations release];
    [filter release];
    [lastRefresh release];
    [super dealloc];
}

- (void)viewDidLoad
{
    locationManager = [CLLocationManager new];
    [locationManager startUpdatingLocation];
    
    self.navigationItem.rightBarButtonItem.target = self;
    self.navigationItem.rightBarButtonItem.action = @selector(refreshStations:);
    self.navigationItem.leftBarButtonItem.target = self;
    self.navigationItem.leftBarButtonItem.action = @selector(about:);
    
    _tableView.rowHeight = [StationTableViewCell cell].frame.size.height;
    
    if (!mapView)
    {
        mapView = [MapViewController new];
    }
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // if the last refresh was more than 5 minutes ago, refresh. otherwise, just just sort by distance.
    if (!lastRefresh || [[NSDate date] timeIntervalSinceDate:lastRefresh] > kMinimumAutorefreshInterval) 
    {
        [self refreshStations:nil];
    }

    [self sortStations];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [stations count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    StationTableViewCell *cell = (StationTableViewCell*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [StationTableViewCell cell];
    }
    
    NSDictionary* station = [stations objectAtIndex:[indexPath row]];
    [cell setStation:station];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* station = [stations objectAtIndex:[indexPath row]];
    
    [mapView selectStation:station];
    [self.navigationController pushViewController:mapView animated:YES];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [filter release];
    filter = nil;
    
    if (searchText && searchText.length) filter = [searchText retain];
    [self sortStations];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    searchBar.text = nil;
    [filter release];
    filter = nil;
    [self sortStations];
}


#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [self sortStations];
}

@end

@implementation RootViewController (Private)

- (void)refreshStations:(id)sender
{
    [[StationList instance] refreshStationsWithCompletion:^{
        [lastRefresh release];
        lastRefresh = [NSDate new];
        [self sortStations];
    }];
}

NSInteger compareDistance(id stationObj1, id stationObj2, void* ctx)
{
    NSDictionary* station1 = stationObj1;
    NSDictionary* station2 = stationObj2;

    double dist1 = [[station1 objectForKey:@"distance"] doubleValue];
    double dist2 = [[station2 objectForKey:@"distance"] doubleValue];
    return dist1 - dist2;
}

- (void)sortStations
{
    NSArray* rawStations = [[StationList instance] stations];
    
    // calcaulte the distance of each station from our current location (if we have)
    CLLocation* currentLocation = locationManager.location;
    
    // if we have current location, add the distance of each station to the current
    // location and then it will be used for sorting.
    if (currentLocation)
    {
        for (NSDictionary* station in rawStations)
        {
            NSNumber* latitudeNumber = [station objectForKey:@"latitude"];
            NSNumber* longitudeNumber = [station objectForKey:@"longitude"];
            
            CLLocation* stationLocation = [[CLLocation new] initWithLatitude:[latitudeNumber doubleValue] longitude:[longitudeNumber doubleValue]];
            CLLocationDistance distance = [currentLocation distanceFromLocation:stationLocation];
            [station setValue:[NSNumber numberWithDouble:distance] forKey:@"distance"];
        }
    }
    
    // sort stations by distance from current location
    NSArray* sortedStations = [rawStations sortedArrayUsingFunction:compareDistance context:nil];
    
    // filter stations based on filter string.
    NSMutableArray* newStations = [NSMutableArray array];
    for (NSDictionary* station in sortedStations) 
    {
        if ([self filterStation:station]) 
        {
            [newStations addObject:station];
        }
    }
    
    // replace current stations list.
    [stations release];
    stations = [newStations retain];
    
    // reload view
    [self.tableView reloadData];
}

- (BOOL)doesStation:(NSDictionary*)station containKeyword:(NSString*)keyword 
{
    // check if the filter text is in the station name
    if ([station stationName] && [[station stationName] rangeOfString:keyword].length) return YES;
    
    // check if the filter text is in the address
    if ([station address] && [[station address] rangeOfString:keyword].length) return YES;
    
    if ([station tags]) 
    {
        // check if any of the tags match
        for (NSString* tag in [station tags])
        {
            if ([tag rangeOfString:keyword].length) return YES;
        }
    }
    
    return NO;
}

- (BOOL)filterStation:(NSDictionary *)station
{
    if (!filter) return YES;
    
    // split filter to words and see if this station match all the words.
    NSArray* keywords = [filter componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    for (NSString* keyword in keywords)
    {
        // trim any whitespace from the keyword
        keyword = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // skip empty keywords.
        if (!keyword || keyword.length == 0) continue;
        
        // if station does not contain this keyword, we can return NO already.
        if (![self doesStation:station containKeyword:keyword]) 
        {
            return NO;
        }
    }
    
    // station contains all keywords, it should be included in the list.
    return YES;
}

- (void)about:(id)sender
{
    NSString* version = @"1.0";
    NSString* aboutTitle = NSLocalizedString(@"Telobike", @"title for the about message");
    NSString* aboutContents = [NSString stringWithFormat:
                               NSLocalizedString(@"Version: %@\nBy: nirsa & eladb", @"contents of the about message"),
                               version];
    
    NSString* aboutCancel = @"OK";
    NSString* aboutFeedback = @"Feedback";
    
    UIAlertView* about = [[[UIAlertView alloc] initWithTitle:aboutTitle 
                                                    message:aboutContents 
                                                   delegate:self 
                                          cancelButtonTitle:aboutCancel 
                                          otherButtonTitles:aboutFeedback,nil] autorelease];
    [about show];
}

@end