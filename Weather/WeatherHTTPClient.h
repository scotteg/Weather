//
//  WeatherHTTPClient.h
//  Weather
//
//  Created by Scott Gardner on 4/8/14.
//  Copyright (c) 2014 Scott Sherwood. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@protocol WeatherHTTPClientDelegate;

@interface WeatherHTTPClient : AFHTTPSessionManager
@property (weak, nonatomic) id<WeatherHTTPClientDelegate> delegate;
+ (WeatherHTTPClient *)sharedWeatherHTTPClient;
- (instancetype)initWithBaseURL:(NSURL *)url;
- (void)updateWeatherAtLocation:(CLLocation *)location forNumberOfDays:(NSUInteger)number;
@end

@protocol WeatherHTTPClientDelegate <NSObject>
//@optional
- (void)weatherHTTPClient:(WeatherHTTPClient *)client didUpdateWithWeather:(id)weather;
- (void)weatherHTTPClient:(WeatherHTTPClient *)client didFailWithError:(NSError *)error;
@end