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
#import "UIImageView+AFNetworking.h"
#import "WeatherHTTPClient.h"

static NSString * const BaseURLString = @"http://www.raywenderlich.com/demos/weather_sample/";

@interface WTTableViewController () <NSXMLParserDelegate, CLLocationManagerDelegate, UIActionSheetDelegate, WeatherHTTPClientDelegate>
@property (strong, nonatomic) NSDictionary *weather;
@property (strong, nonatomic)CLLocationManager *locationManager;

// Needed only for XML parsing
@property (strong, nonatomic) NSMutableDictionary *currentDict;
@property (strong, nonatomic) NSMutableDictionary *xmlWeatherDict;
@property (copy, nonatomic) NSString *elementName;
@property (strong, nonatomic) NSMutableString *outString;
@end

@implementation WTTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationController.toolbarHidden = NO;
  self.locationManager = [CLLocationManager new];
  self.locationManager.delegate = self;
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
    [strongSelf.tableView reloadData];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    __strong typeof(weakSelf)strongSelf = weakSelf;
    [strongSelf showErrorRetrievingWeatherAlert:error];
  }];
  
  [operation start];
}

- (IBAction)xmlTapped:(id)sender
{
  AFHTTPRequestOperation *operation = [self operationForRequestWithFormat:@"xml"];
  operation.responseSerializer = [AFXMLParserResponseSerializer serializer];
  
  __weak typeof(self)weakSelf = self;
  
  [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSXMLParser *XMLParser = (NSXMLParser *)responseObject;
    [XMLParser setShouldProcessNamespaces:YES];
    
    XMLParser.delegate = self;
    [XMLParser parse];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    __strong typeof(weakSelf)strongSelf = weakSelf;
    [strongSelf showErrorRetrievingWeatherAlert:error];
  }];
  
  [operation start];
}

- (IBAction)clientTapped:(id)sender
{
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"AFHTTPSessionManager" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"HTTP GET", @"HTTP POST", nil];
  [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction)apiTapped:(id)sender
{
  [self.locationManager startUpdatingLocation];
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
  
  NSURL *url = [NSURL URLWithString:daysWeather.weatherIconURL];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  UIImage *placeholderImage = [UIImage imageNamed:@"placeholder"];
  
  __weak UITableViewCell *weakCell = cell;
  
  [cell.imageView setImageWithURLRequest:request
                        placeholderImage:placeholderImage
                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                   weakCell.imageView.image = image;
                                   [weakCell setNeedsLayout];
                                 } failure:nil];
  
  return cell;
}

#pragma mark - UITableViewDataSource

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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Navigation logic may go here. Create and push another view controller.
}

#pragma mark - NSXMLParserDelegate

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
  self.xmlWeatherDict = [NSMutableDictionary dictionary];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
  self.elementName = qName;
  
  if ([qName isEqualToString:@"current_condition"] ||
      [qName isEqualToString:@"weather"] ||
      [qName isEqualToString:@"request"]) {
    self.currentDict = [NSMutableDictionary dictionary];
  }
  
  self.outString = [NSMutableString string];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
  if (!self.elementName) {
    return;
  }
  
  [self.outString appendFormat:@"%@", string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
  if ([qName isEqualToString:@"current_condition"] ||
      [qName isEqualToString:@"request"]) {
    self.xmlWeatherDict[qName] = @[self.currentDict];
    self.currentDict = nil;
  } else if ([qName isEqualToString:@"weather"]) {
    NSMutableArray *array = self.xmlWeatherDict[@"weather"] ?: [NSMutableArray array];
    
    [array addObject:self.currentDict];
    
    self.xmlWeatherDict[@"weather"] = array;
    self.currentDict = nil;
  } else if ([qName isEqualToString:@"value"]) {
    // Ingnore
  } else if ([qName isEqualToString:@"weatherDesc"] ||
             [qName isEqualToString:@"weatherIconUrl"]) {
    NSDictionary *dict = @{@"value" : self.outString};
    NSArray *array = @[dict];
    self.currentDict[qName] = array;
  } else if (qName) {
    self.currentDict[qName] = self.outString;
  }
  
  self.elementName = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
  self.weather = @{@"data" : self.xmlWeatherDict};
  self.title = @"XML Retrieved";
  [self.tableView reloadData];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
  CLLocation *newLocation = [locations lastObject]; // Most recent location
  
  if ([newLocation.timestamp timeIntervalSinceNow] > 300.0) { // Ignore location if > 5 minutes old
    return;
  }
  
  [self.locationManager stopUpdatingLocation];
  WeatherHTTPClient *client = [WeatherHTTPClient sharedWeatherHTTPClient];
  client.delegate = self;
  [client updateWeatherAtLocation:newLocation forNumberOfDays:5];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == [actionSheet cancelButtonIndex]) {
    return;
  }
  
  NSURL *baseUrl = [NSURL URLWithString:BaseURLString];
  NSDictionary *parameters = @{@"format" : @"json"};
  
  AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseUrl];
  manager.responseSerializer = [AFJSONResponseSerializer serializer];
  
  __weak typeof(self)weakSelf = self;
  
  if (buttonIndex == 0) { // GET
    [manager GET:@"weather.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
      __strong typeof(weakSelf)strongSelf = weakSelf;
      strongSelf.weather = responseObject;
      strongSelf.title = @"HTTP GET";
      [strongSelf.tableView reloadData];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
      __strong typeof(weakSelf)strongSelf = weakSelf;
      [strongSelf showErrorRetrievingWeatherAlert:error];
    }];
  } else if (buttonIndex == 1) { // POST
    [manager POST:@"weather.php" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
      __strong typeof(weakSelf)strongSelf = weakSelf;
      strongSelf.weather = responseObject;
      strongSelf.title = @"HTTP POST";
      [strongSelf.tableView reloadData];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
      __strong typeof(weakSelf)strongSelf = weakSelf;
      [strongSelf showErrorRetrievingWeatherAlert:error];
    }];
  }
}

#pragma mark - WeatherHTTPClientDelegate

- (void)weatherHTTPClient:(WeatherHTTPClient *)client didUpdateWithWeather:(id)weather
{
  self.weather = weather;
  self.title = @"API Updated";
  [self.tableView reloadData];
}

- (void)weatherHTTPClient:(WeatherHTTPClient *)client didFailWithError:(NSError *)error
{
  [self showErrorRetrievingWeatherAlert:error];
}

@end