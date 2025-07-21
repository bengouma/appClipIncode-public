/*!
  @header TMXProfileHandle.h

  @copyright ThreatMetrix. All rights reserved.
*/

#ifndef __TMXPROFILEHANDLE__
#define __TMXPROFILEHANDLE__

#import <Foundation/Foundation.h>

#define TMX_NAME_PASTE2( a, b) a##b
#define TMX_NAME_PASTE( a, b) TMX_NAME_PASTE2( a, b)

#ifndef TMX_PREFIX_NAME
#define NO_COMPAT_CLASS_NAME
#define TMX_PREFIX_NAME
#endif

#define TMXProfileHandle TMX_NAME_PASTE(TMX_PREFIX_NAME, TMXProfileHandle)


@interface TMXProfileHandle : NSObject

/*! @abstract Session ID used for profiling. */
@property(nonatomic, readonly) NSString *sessionID;

-(instancetype) init NS_UNAVAILABLE;
+(instancetype) allocWithZone:(struct _NSZone *)zone NS_UNAVAILABLE;
+(instancetype) new NS_UNAVAILABLE;

/*!
 * @abstract Cancels profiling if running, if profiling is finished just returns.
 */
-(void) cancel;

/*!
 * @abstract Forces sending behavioural biometrics data to backend ahead of scheduled time.
 * This method is effective once per profiling.
 * @Discussion This is useful to ensure all data is sent immediately before needing a risk decision.
 * @Note calling this method does not stop collection of biometrics information.
 */
-(void) sendBehavioSecData;

/*!
* @abstract Stops biometric data collection.
* @discussion This method disables the biometric module to ensure no further data collection occurs in the background. Useful when biometric data collection is only needed for specific screens like login and to avoid unintended data collection.
*/
-(void)stopBehavioSecDataCollection;

@end

#endif
