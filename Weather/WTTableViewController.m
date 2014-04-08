//
//  WTTableViewController.m
//  Weather
//
//  Created by Scott on 26/01/2013.
//  Updated by Joshua Greene 16/12/2013.
//
//  Copyright (c) 2013 Scott Sherwood. All rights reserved.
//

#import "WTTableViewController.h"
#import "WeatherAnimationViewController.h"
#import "NSDictionary+weather.h"
#import "NSDictionary+weather_package.h"

static NSString * const BaseURLString = @"http://www.raywenderlich.com/demos/weather_sample/";

@interface WTTableViewController ()
@property(strong) NSDictionary *weather;
@end

@implementation WTTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationController.toolbarHidden = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if([segue.identifier isEqualToString:@"WeatherDetailSegue"]) {
    UITableViewCell *cell = (UITableViewCell *)sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    WeatherAnimationViewController *weatherAnimationVC = (WeatherAnimationViewController *)segue.destinationViewController;
    
    NSDictionary *weatherDict;
    switch (indexPath.section) {
      case 0: {
        weatherDict = self.weather.currentCondition;
        break;
      }
      case 1: {
        weatherDict = [self.weather upcomingWeather][indexPath.row];
        break;
      }
      default: {
        break;
      }
    }
    weatherAnimationVC.weatherDictionary = weatherDict;
  }
}

#pragma mark - Actions

- (IBAction)clear:(id)sender
{
  self.title = @"";
  self.weather = nil;
  [self.tableView reloadData];
}

- (IBAction)jsonTapped:(id)sender
{
  // Create operation with request
  AFHTTPRequestOperation *operation = [self operationForRequestWithFormat:@"json"];
  operation.responseSerializer = [AFJSONResponseSerializer serializer]; // Read response as JSON
  
  __weak typeof(self)weakSelf = self;
  
  // Cache response object and reload table view to display
  [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
    __strong typeof(weakSelf)strongSelf = weakSelf;
    
    strongSelf.weather = (NSDictionary *)responseObject;
    strongSelf.title = @"JSON Retrieved";
    [strongSelf.tableView reloadData];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    [self showErrorRetrievingWeatherAlert:error];
  }];
  
  // Don't forget to start!
  [operation start];
}

- (IBAction)plistTapped:(id)sender
{
  AFHTTPRequestOperation *operation = [self operationForRequestWithFormat:@"plist"];
  operation.responseSerializer = [AFPropertyListResponseSerializer serializer];
  
  __weak typeof(self)weakSelf = self;
  
  [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
    __strong typeof(weakSelf)strongSelf = weakSelf;
    
    strongSelf.weather = (NSDictionary *)responseObject;
    strongSelf.title = @"PLIST Retrieved";
    [self.tableView reloadData];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    [self showErrorRetrievingWeatherAlert:error];
  }];
  
  [operation start];
}

- (IBAction)xmlTapped:(id)sender
{
  
}

- (IBAction)clientTapped:(id)sender
{
  
}

- (IBAction)apiTapped:(id)sender
{
  
}

- (AFHTTPRequestOperation *)operationForRequestWithFormat:(NSString *)format
{
  NSString *string = [NSString stringWithFormat:@"%@weather.php?format=%@", BaseURLString, format];
  NSURL *url = [NSURL URLWithString:string];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
  return operation;
}

- (void)showErrorRetrievingWeatherAlert:(NSError *)error
{
  [[[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (!self.weather) {
    return 0;
  }
  
  switch (section) {
    case 0:
      return 1;
      
    case 1: {
      NSArray *upcomingWeather = [self.weather upcomingWeather];
      return [upcomingWeather count];
    }
      
    default:
      return 0;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"WeatherCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
  [self configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (UITableViewCell *)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
  NSDictionary *daysWeather;
  
  switch (indexPath.section) {
    case 0:
      daysWeather = [self.weather currentCondition];
      break;
      
    case 1: {
      NSArray *upcomingWeather = [self.weather upcomingWeather];
      daysWeather = upcomingWeather[indexPath.row];
      break;
    }
      
    default:
      break;
  }
  
  cell.textLabel.text = [daysWeather weatherDescription];
  
  // Further customize cell later
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Navigation logic may go here. Create and push another view controller.
}

@end