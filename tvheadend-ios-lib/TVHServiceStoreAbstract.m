//
//  TVHServiceStore.m
//  TvhClient
//
//  Created by Luis Fernandes on 08/12/13.
//  Copyright (c) 2013 Luis Fernandes.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "TVHServiceStoreAbstract.h"
#import "TVHService.h"
#import "TVHMux.h"
#import "TVHServer.h"

@interface TVHServiceStoreAbstract()
@property (nonatomic, weak) TVHApiClient *apiClient;
@property (nonatomic, strong) NSArray *services;
@end

@implementation TVHServiceStoreAbstract

- (id)initWithTvhServer:(TVHServer*)tvhServer {
    self = [super init];
    if (!self) return nil;
    self.tvhServer = tvhServer;
    self.apiClient = [self.tvhServer apiClient];
    return self;
}

- (NSArray*)services {
    if ( !_services ) {
        _services = [[NSArray alloc] init];
    }
    return _services;
}


#pragma mark Api Client delegates

- (NSString*)apiMethod {
    return nil;
}

- (NSString*)apiPath {
    return nil;
}

- (NSDictionary*)apiParameters {
    return nil;
}

- (void)fetchServices {
    if (!self.tvhServer.userHasAdminAccess) {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    
    [self.apiClient doApiCall:self success:^(NSURLSessionDataTask *task, id responseObject) {
        typeof (self) strongSelf = weakSelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ( [strongSelf fetchedServiceData:responseObject] ) {
                [strongSelf signalDidLoadServices];
            }
        });
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"[TV Services HTTPClient Error]: %@", error.localizedDescription);
    }];
    
}

- (BOOL)fetchedServiceData:(NSDictionary *)json {
    if (![TVHApiClient checkFetchedData:json]) {
        return false;
    }
    
    NSArray *entries = [json objectForKey:@"entries"];
    NSMutableArray *services = [self.services mutableCopy];
    
    for (id obj in entries) {
        TVHService *service = [[TVHService alloc] initWithTvhServer:self.tvhServer];
        [service updateValuesFromDictionary:obj];
        
        [self updateServiceToArray:service array:services];
    }
    
    self.services = [services copy];
    
#ifdef TESTING
    NSLog(@"[Loaded Services]: %d", (int)[self.services count]);
#endif
    return true;
}

- (void)updateServiceToArray:(TVHService*)serviceItem array:(NSMutableArray*)services {
    NSUInteger indexOfObject = [services indexOfObject:serviceItem];
    if ( indexOfObject == NSNotFound ) {
        [services addObject:serviceItem];
    } else {
        // update
        TVHService *foundService = [services objectAtIndex:indexOfObject];
        [foundService updateValuesFromService:serviceItem];
    }
}

- (NSArray*)servicesForMux:(TVHMux*)adapterMux {
    NSPredicate *predicate;
    if ( adapterMux.frequency ) {
        predicate = [NSPredicate predicateWithFormat:@"multiplex == %@ AND network == %@", adapterMux.name, adapterMux.network];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"mux == %@ AND satconf == %@ AND network == %@", adapterMux.freq, adapterMux.satconf, adapterMux.network];
    }
    NSArray *filteredArray = [self.services filteredArrayUsingPredicate:predicate];
    
    return [filteredArray sortedArrayUsingSelector:@selector(compareByName:)];
}

- (void)signalDidLoadServices {
    
}

@end
