//
//  TVHDvrActions.m
//  TVHeadend iPhone Client
//
//  Created by Luis Fernandes on 2/28/13.
//  Copyright 2013 Luis Fernandes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

// note: this file is a gigantic hack :( this needs refactoring ASAP...

#import "TVHDvrActions.h"
#import "TVHJsonClient.h"
#import "TVHDvrStore.h"
#import "TVHServer.h"

@implementation TVHDvrActions

+ (void)doDvrAction:(NSString*)action onUrl:(NSString*)url withId:(NSInteger)idint withIdName:(NSString*)idName withConfigName:(NSString*)configName withTvhServer:(TVHServer*)tvhServer {
    TVHApiClient *httpClient = tvhServer.apiClient;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSString stringWithFormat:@"%lu", (unsigned long)idint ],
                                   idName,
                                   action,
                                   @"op",
                                   configName,
                                   @"configName",nil
                            ];
    
    if ([tvhServer isVersionFour]) {
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                 [NSString stringWithFormat:@"%lu", (unsigned long)idint ],
                 idName,
                 @"",
                 @"config_uuid",nil
                 ];
    }
    
    [httpClient postPath:url parameters:params success:^(NSURLSessionDataTask *task, NSDictionary *json) {
        
        NSInteger success = 1;
        if (![tvhServer isVersionFour]) {
            success = [[json objectForKey:@"success"] intValue];
        }
        [TVHDvrActions postRecordingSuccess:success withAction:action withInt:(int)idint];
        
        // reload dvr
        id <TVHDvrStore> store = [tvhServer dvrStore];
        [store fetchDvr];
        
        //NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        //NSLog(@"Request Successful, response '%@'", responseStr);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
#ifdef TESTING
        NSLog(@"[DVR ACTIONS ERROR]: %@", error.localizedDescription);
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvrActionDidErrorNotification
             object:error];
        });
    }];

}

+ (void)postRecordingSuccess:(NSInteger)success withAction:(id)action withInt:(int)idint
{
    if ( success ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvrActionDidSucceedNotification
             object:action];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:TVHDidSuccessfulyAddEpgToRecording
                                                                object:[NSNumber numberWithInt:(int)idint]];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvrActionDidReturnErrorNotification
             object:action];
        });
    }

}

+ (void)doIdnodeAction:(NSString*)action withData:(NSDictionary*)params withTvhServer:(TVHServer*)tvhServer
{
    return [TVHDvrActions doAction:[@"api/idnode/" stringByAppendingString:action] withData:params withTvhServer:tvhServer];
}

+ (void)doAction:(NSString*)action withData:(NSDictionary*)params withTvhServer:(TVHServer*)tvhServer
{
    TVHApiClient *httpClient = [tvhServer apiClient];
    
    [httpClient postPath:action parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvrActionDidSucceedNotification
             object:action];
        });
        
        // reload dvr
        id <TVHDvrStore> store = [tvhServer dvrStore];
        [store fetchDvr];
        id <TVHAutoRecStore> autorecstore = [tvhServer autorecStore];
        [autorecstore fetchDvrAutoRec];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
#ifdef TESTING
        NSLog(@"[DVR ACTIONS ERROR]: %@", error.localizedDescription);
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:TVHDvrActionDidReturnErrorNotification
             object:action];
        });
    }];
    
}


+ (void)addRecording:(NSInteger)eventId withConfigName:(NSString*)configName withTvhServer:(TVHServer*)tvhServer  {
    NSString *url = @"dvr";
    NSString *idName = @"eventId";
    if ([tvhServer isVersionFour]) {
        url = @"api/dvr/entry/create_by_event";
        idName = @"event_id";
    }
    [TVHDvrActions doDvrAction:@"recordEvent" onUrl:url withId:eventId withIdName:idName withConfigName:configName withTvhServer:tvhServer];
}

+ (void)cancelRecording:(NSInteger)entryId withTvhServer:(TVHServer*)tvhServer {
    [TVHDvrActions doDvrAction:@"cancelEntry" onUrl:@"dvr" withId:entryId withIdName:@"entryId" withConfigName:nil withTvhServer:tvhServer];
}

+ (void)deleteRecording:(NSInteger)entryId withTvhServer:(TVHServer*)tvhServer {
    [TVHDvrActions doDvrAction:@"deleteEntry" onUrl:@"dvr" withId:entryId withIdName:@"entryId" withConfigName:nil withTvhServer:tvhServer];
}

+ (void)addAutoRecording:(NSInteger)eventId withConfigName:(NSString*)configName withTvhServer:(TVHServer*)tvhServer  {
    NSString *url = @"dvr";
    NSString *idName = @"eventId";
    if ([tvhServer isVersionFour]) {
        url = @"api/dvr/autorec/create_by_series";
        idName = @"event_id";
    }
    [TVHDvrActions doDvrAction:@"recordSeries" onUrl:url withId:eventId withIdName:idName withConfigName:configName withTvhServer:tvhServer];
}

+ (NSString*)jsonArrayString:(id)params
{
    NSData* json = [NSJSONSerialization dataWithJSONObject:params options:(NSJSONWritingOptions)0 error:nil];
    return [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
}

@end
