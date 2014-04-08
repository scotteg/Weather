//
//  WeatherHTTPClient.m
//  Weather
//
//  Created by Scott Gardner on 4/8/14.
//  Copyright (c) 2014 Scott Sherwood. All rights reserved.
//

#import "WeatherHTTPClient.h"

static NSString * const WWOAPIKey = @"u6v7ux8ht78kktkryv5uknvu";
static NSString * const WWOURLString = @"http://api.worldweatheronline.com/free/v1/";

@implementation WeatherHTTPClient

+ (WeatherHTTPClient *)sharedWeatherHTTPClient
{
  static WeatherHTTPClient *_sharedWeatherHttpClient = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedWeatherHttpClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:WWOURLString]];
  });
  
  return _sharedWeatherHttpClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
  if (self = [super initWithBaseURL:url]) {
    self.requestSerializer = [AFJSONRequestSerializer serializer];
    self.responseSerializer = [AFJSONResponseSerializer serializer];
  }
  
  return self;
}

- (void)updateWeatherAtLocation:(CLLocation *)location forNumberOfDays:(NSUInteger)number
{
  NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  parameters[@"num_of_days"] = @(number);
  parameters[@"q"] = [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
  parameters[@"format"] = @"json";
  parameters[@"key"] = WWOAPIKey;
  
  __weak typeof(self)weakSelf = self;
  
  [self GET:@"weather.ashx" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
    __strong typeof(weakSelf)strongSelf = weakSelf;
    if ([strongSelf.delegate respondsToSelector:@selector(weatherHTTPClient:didUpdateWithWeather:)]) {
      [strongSelf.delegate weatherHTTPClient:self didUpdateWithWeather:responseObject];
    }
  } failure:^(NSURLSessionDataTask *task, NSError *error) {
    __strong typeof(weakSelf)strongSelf = weakSelf;
    if ([strongSelf.delegate respondsToSelector:@selector(weatherHTTPClient:didFailWithError:)]) {
      [strongSelf.delegate weatherHTTPClient:self didFailWithError:error];
    }
  }];
}

@end
