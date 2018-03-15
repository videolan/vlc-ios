#import <Foundation/Foundation.h>
#import "HTTPResponse.h"


@interface HTTPDataResponse : NSObject <HTTPResponse>
{
	NSUInteger offset;
	NSData *data;
}
@property (retain, nonatomic) NSString *contentType;

- (id)initWithData:(NSData *)data;

@end
