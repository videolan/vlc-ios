//
//  BoxModelBuilder.h
//  BoxSDK
//
//  Created on 11/21/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAPIRequestBuilder.h"
#import "BoxSDKConstants.h"

/**
 * BoxModelBuilder is an request builder for minimum box model.
 */
@interface BoxModelBuilder : BoxAPIRequestBuilder

/**
 * The type of object returned by the API.
 */
@property (nonatomic, readwrite, strong) BoxAPIItemType * type;

/**
 * The ID of this model. This field is unique for all objects of the same type but may
 * not be unique across model types.
 */
@property (nonatomic, readwrite, strong) NSString *modelID;

@end
