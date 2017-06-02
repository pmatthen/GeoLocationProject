//
//  ViewController.m
//  GeoLocationProject
//
//  Created by Poulose Matthen on 23/05/17.
//  Copyright © 2017 Poulose Matthen. All rights reserved.
//

#import "ViewController.h"
#import <FlickrKit.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Slideshow Variables
    
    NSString *keyword = @"Sky"; // Sky, Clock
    int numberOfSegments = 5; // 24
    int displayTime = 5; // 1
    int photosPerSegment = 5; // 2
    int advanceTime = 360000; // 3600
    int revolutions = 1; // 10
// ------------------------------
    
    // Convert String Date to NSDate, add time advance, and convert back to String Date
    
    NSString *startDate = @"2016-03-09 14:00:00";
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *startDateNSDATE = [dateFormat dateFromString:startDate];
    NSTimeInterval timeToAdvance = advanceTime * revolutions;
    NSDate *endDateNSDATE = [startDateNSDATE dateByAddingTimeInterval:timeToAdvance];
    
    NSString *endDate = [dateFormat stringFromDate:endDateNSDATE];
    endDate = endDate;

// ------------------------------
    
    // Create empty slideshow dictionary
    
    NSMutableDictionary *slideShowDictionary = [NSMutableDictionary new];
    slideShowDictionary = (NSMutableDictionary *) [self createEmptyDictionary:revolutions segments:numberOfSegments startDate:startDateNSDATE endDate:endDateNSDATE advanceTime:advanceTime displayTime:displayTime photosPer:photosPerSegment];
    
// ------------------------------
    
    dispatch_group_t serviceGroup = dispatch_group_create(); // For Async Code
    
    int pageNumber = 1;
    __block BOOL slideshowArrayIncomplete = true;
    __block int responsePages = 2;
    
    while ((slideshowArrayIncomplete) || (pageNumber == responsePages)) {
        slideshowArrayIncomplete = false;
        
        FKFlickrPhotosSearch *search = [[FKFlickrPhotosSearch alloc] init];
        search.text = keyword;
        search.per_page = @"500";
        search.page = [NSString stringWithFormat:@"%d", pageNumber];
        search.min_taken_date = startDate;
        search.max_taken_date = endDate;
        search.has_geo = @"1";
        search.extras = @"date_taken, geo, url_sq, url_t, url_s, url_q, url_m, url_n, url_z, url_c, url_l, url_o";
        
        dispatch_group_enter(serviceGroup); // Enters Async Code Section
        
        [[FlickrKit sharedFlickrKit] call:search completion:^(NSDictionary *response, NSError *error) {
            if (response) {
//                NSLog(@"response = %@", response);
                NSNumber *responsePagesNumber = [response valueForKeyPath:@"photos.pages"];
                responsePages = [responsePagesNumber intValue];
                
                NSLog(@"responsePages = %d", responsePages);
                
                for (NSDictionary *photoDictionary in [response valueForKeyPath:@"photos.photo"]) {
                    
                    NSString *photoDateString = [photoDictionary valueForKey:@"datetaken"];
                    NSDate *photoDateNSDATE = [dateFormat dateFromString:photoDateString];
                    
                    NSString *photoLongitudeString = [photoDictionary valueForKey:@"longitude"];
                    float photoLongitude = [photoLongitudeString floatValue];
                    
                    if ([self date:photoDateNSDATE isBetweenDate:startDateNSDATE andDate:endDateNSDATE]) { // Check whether the photoDate is between date range of slideshow.
                        NSArray *revolutionArray = [NSArray new];
                        revolutionArray = [slideShowDictionary valueForKey:@"revolutionsArray"];
                        
                        for (int i = 0; i < [revolutionArray count]; i++) { // Loop through the number of revolutions
                            NSDictionary *revolutionDictionary = [NSDictionary new];
                            revolutionDictionary = revolutionArray[i];
                            
                            NSDate *revolutionStartDateNSDate = [NSDate new];
                            revolutionStartDateNSDate = [revolutionDictionary valueForKey:@"revolutionStartTime"];
                            
                            NSDate *revolutionEndDateNSDate = [NSDate new];
                            revolutionEndDateNSDate = [revolutionDictionary valueForKey:@"revolutionEndTime"];
                            
                            if ([self date:photoDateNSDATE isBetweenDate:revolutionStartDateNSDate andDate:revolutionEndDateNSDate]) { // Check whether the photoDate is between the date range of the current revolution
                                NSArray *segmentArray = [NSArray new];
                                segmentArray = [revolutionDictionary valueForKey:@"segmentArray"];
                                
                                for (int j = 0; j < [segmentArray count]; j++) { // Loop through the number of segments in the current revolution
                                    NSDictionary *segmentDictionary = [NSDictionary new];
                                    segmentDictionary = segmentArray[j];
                                    
                                    NSNumber *segmentLongitudeBegin = [segmentDictionary valueForKey:@"longitudeBegin"];
                                    NSNumber *segmentLongitudeEnd = [segmentDictionary valueForKey:@"longitudeEnd"];
                                    
                                    if (([segmentLongitudeBegin floatValue] <= photoLongitude) && ([segmentLongitudeEnd floatValue] > photoLongitude)) { // Check whether the longitude of the photo is between the longitude range of the current segment
                                        NSMutableArray *photoArray = [segmentDictionary valueForKey:@"photoArray"];
                                        
                                        if (([photoArray count] < photosPerSegment) && ([photoDictionary valueForKey:@"url_l"] != nil)) { // Check if segments photoArray is not full
                                            NSString *photoURLString = [photoDictionary valueForKey:@"url_l"];
                                            
                                            NSLog(@"==========");
                                            NSLog(@"datetaken = %@", [photoDictionary valueForKey:@"datetaken"]);
                                            NSLog(@"longitude = %@", [photoDictionary valueForKey:@"longitude"]);
                                            NSLog(@"url_l = %@", [photoDictionary valueForKey:@"url_l"]);
                                            
                                            // Add photo to segments photoArray
                                            
                                            NSMutableArray *tempRevolutionsArray = [NSMutableArray new];
                                            tempRevolutionsArray = [slideShowDictionary valueForKey:@"revolutionsArray"];
                                            NSMutableDictionary *tempRevolutionsDictionary = [NSMutableDictionary new];
                                            tempRevolutionsDictionary = [tempRevolutionsArray objectAtIndex:i];
                                            NSMutableArray *tempSegmentArray = [NSMutableArray new];
                                            tempSegmentArray = [tempRevolutionsDictionary valueForKey:@"segmentArray"];
                                            NSMutableDictionary *tempSegmentDictionary = [NSMutableDictionary new];
                                            tempSegmentDictionary = [tempSegmentArray objectAtIndex:j];
                                            photoArray = [tempSegmentDictionary valueForKey:@"photoArray"];
                                            
                                            [photoArray addObject:photoURLString];
                                            
                                            [tempSegmentDictionary removeObjectForKey:@"photoArray"];
                                            [tempSegmentDictionary setObject:photoArray forKey:@"photoArray"];
                                            [tempSegmentArray setObject:tempSegmentDictionary atIndexedSubscript:j];
                                            [tempRevolutionsDictionary removeObjectForKey:@"segmentArray"];
                                            [tempRevolutionsDictionary setObject:tempSegmentArray forKey:@"segmentArray"];
                                            [tempRevolutionsArray setObject:tempRevolutionsDictionary atIndexedSubscript:i];
                                            [slideShowDictionary removeObjectForKey:@"revolutionsArray"];
                                            [slideShowDictionary setObject:tempRevolutionsArray forKey:@"revolutionsArray"];
                                            
                                            if (([photoArray count] + 1) < photosPerSegment) {
                                                slideshowArrayIncomplete = true; // Check again if segments photo array is not full, and if not, note that the slideshow is not complete.
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                NSLog(@"No response");
            }
            dispatch_group_leave(serviceGroup); // Exit Async Code Section
        }];
        dispatch_group_wait(serviceGroup,DISPATCH_TIME_FOREVER);
        pageNumber++;
        [self generateReport:slideShowDictionary photosPer:photosPerSegment pageNumber:pageNumber];
    }
    
    NSLog(@"PAGENUMBERS = %d", pageNumber);
    NSLog(@"slideshowDictionary = %@", slideShowDictionary);
}

-(BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate {
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

- (NSDictionary *)createEmptyDictionary:(int)revolutions segments:(int)numberOfSegmentsInput startDate:(NSDate *)startDateInput endDate:(NSDate *)endDateInput advanceTime:(int)advanceTimeInput displayTime:(int)displayTimeInput photosPer:(int) photosPerSegmentInput  {
    
    NSMutableDictionary *slideshowDictionary = [NSMutableDictionary new];
    NSMutableArray *revolutionsArray = [NSMutableArray new];
    NSNumber *longitudeBegin = [NSNumber new];
    NSNumber *longitudeEnd = [NSNumber new];
    
    float longitudeSegmentValue = 360 / numberOfSegmentsInput;
    
    [slideshowDictionary setValue:startDateInput forKey:@"slideshowStartTime"];
    [slideshowDictionary setValue:endDateInput forKey:@"slideshowEndTime"];
    
    for (int i = 0; i < revolutions; i++) {
        NSMutableDictionary *revolutionDictionary = [NSMutableDictionary new];
        NSMutableArray *segmentArray = [NSMutableArray new];
        longitudeBegin = [NSNumber numberWithFloat:-180.0];
        longitudeEnd = [NSNumber numberWithFloat:[longitudeBegin floatValue] + longitudeSegmentValue];
        
        for (int j = 0; j < numberOfSegmentsInput; j++) {
            NSMutableDictionary *segmentDictionary = [NSMutableDictionary new];
            
            [segmentDictionary setValue:longitudeBegin forKey:@"longitudeBegin"];
            [segmentDictionary setValue:longitudeEnd forKey:@"longitudeEnd"];
            
            NSMutableArray *photoArray = [NSMutableArray new];
            [segmentDictionary setValue:photoArray forKey:@"photoArray"];
            
            longitudeBegin = [NSNumber numberWithFloat:[longitudeBegin floatValue] + longitudeSegmentValue];
            longitudeEnd = [NSNumber numberWithFloat:[longitudeEnd floatValue] + longitudeSegmentValue];
            
            [segmentArray addObject:segmentDictionary];
        }
        
        [revolutionDictionary setValue:segmentArray forKey:@"segmentArray"];
// -------------------------------------------------------
        [revolutionDictionary setValue:startDateInput forKey:@"revolutionStartTime"];
        
        NSTimeInterval timeToAdvance = advanceTimeInput;
        NSDate *revolutionEndDate = [startDateInput dateByAddingTimeInterval:timeToAdvance];
        
        [revolutionDictionary setValue:revolutionEndDate forKey:@"revolutionEndTime"];
        
        startDateInput = revolutionEndDate;
// -------------------------------------------------------
        
        [revolutionsArray addObject:revolutionDictionary];
    }
    
    [slideshowDictionary setValue:revolutionsArray forKey:@"revolutionsArray"];
    
    return slideshowDictionary;
}

- (void)generateReport:(NSDictionary *)slideshowDictionaryInput photosPer:(int)photosPerInput pageNumber:(int)pageNumberInput {
    
    NSArray *revolutionsArray = [NSArray new];
    revolutionsArray = [slideshowDictionaryInput valueForKey:@"revolutionsArray"];
    
    NSLog(@"==========");
    NSLog(@"Count = %d", pageNumberInput);
    
    for (int i = 0; i < [revolutionsArray count]; i++) {
        NSLog(@"REVOLUTION%d", i);
        
        NSDictionary *revolutionDictionary = [NSDictionary new];
        revolutionDictionary = [revolutionsArray objectAtIndex:i];
        
        NSLog(@"revolutionStartTime = %@", [revolutionDictionary valueForKey:@"revolutionStartTime"]);
        NSLog(@"revolutionEndTime = %@", [revolutionDictionary valueForKey:@"revolutionEndTime"]);
        
        NSArray *segmentArray = [NSArray new];
        segmentArray = [revolutionDictionary valueForKey:@"segmentArray"];
        
        for (int j = 0; j < [segmentArray count]; j++) {
            NSLog(@"SEGMENT%d", j);
            
            NSDictionary *segmentDictionary = [NSDictionary new];
            segmentDictionary = [segmentArray objectAtIndex:j];
            
            NSLog(@"longitudeBegin = %@", [segmentDictionary valueForKey:@"longitudeBegin"]);
            NSLog(@"longitudeEnd = %@", [segmentDictionary valueForKey:@"longitudeEnd"]);
            
            NSArray *photoArray = [NSArray new];
            photoArray = [segmentDictionary valueForKey:@"photoArray"];
            
            NSLog(@"Photos %lu out of %d", (unsigned long)[photoArray count], photosPerInput);
        }
    }
}

@end
