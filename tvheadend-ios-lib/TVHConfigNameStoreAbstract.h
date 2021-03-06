//
//  TVHConfigNameStore.h
//  TvhClient
//
//  Created by Luis Fernandes on 7/17/13.
//  Copyright (c) 2013 Luis Fernandes. 
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//


#import "TVHConfigName.h"
#import "TVHApiClient.h"

@class TVHServer;

@interface TVHConfigNameStoreAbstract : NSObject <TVHApiClientDelegate>
@property (nonatomic, weak) TVHServer *tvhServer;

- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)fetchConfigNames;
- (NSString*)nameForId:(NSString*)uuid;
- (NSString*)idForName:(NSString*)name;
- (NSArray*)configNamesAsString;
@end
