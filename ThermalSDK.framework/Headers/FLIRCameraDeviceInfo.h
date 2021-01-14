//
//  FLIRCameraDeviceInfo.h
//
//  Copyright © 2019 Flir Systems. All rights reserved.
//

#ifndef FLIRCameraDeviceInfo_h
#define FLIRCameraDeviceInfo_h

#endif


/**
 *  Camera device information.
 */
@interface FLIRCameraDeviceInfo : NSObject

/**
 *  @property hostName
 */
@property (readonly) NSString *hostName;

/**
 *  @property productName
 */
@property (readonly) NSString *productName;

/**
 *   @property ipAddress
 */
@property (readonly) NSString *ipAddress;

/**
 *   @property imageWidth
 */
@property (readonly) NSNumber *imageWidth;

/**
 *   @property imageHeight
 */
@property (readonly) NSNumber *imageHeight;

/**
 *   @property netService
 */
@property (readonly) NSNetService* netService;

/**
 *   Create a new FLIRCameraDeviceInfo from a NSNetService
 *
 *  @param source netService
 */
-(void) create:(id)source;

@end
