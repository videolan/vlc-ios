//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import <Foundation/Foundation.h>
#import "SoapAction.h"

@interface SoapActionsWANCommonInterfaceConfig1 : SoapAction {
    }

//SOAP

-(NSInteger)SetEnabledForInternetWithNewEnabledForInternet:(NSString*)newenabledforinternet;
-(NSInteger)GetEnabledForInternetWithOutNewEnabledForInternet:(NSMutableString*)newenabledforinternet;
-(NSInteger)GetCommonLinkPropertiesWithOutNewWANAccessType:(NSMutableString*)newwanaccesstype OutNewLayer1UpstreamMaxBitRate:(NSMutableString*)newlayer1upstreammaxbitrate OutNewLayer1DownstreamMaxBitRate:(NSMutableString*)newlayer1downstreammaxbitrate OutNewPhysicalLinkStatus:(NSMutableString*)newphysicallinkstatus;
-(NSInteger)GetWANAccessProviderWithOutNewWANAccessProvider:(NSMutableString*)newwanaccessprovider;
-(NSInteger)GetMaximumActiveConnectionsWithOutNewMaximumActiveConnections:(NSMutableString*)newmaximumactiveconnections;
-(NSInteger)GetTotalBytesSentWithOutNewTotalBytesSent:(NSMutableString*)newtotalbytessent;
-(NSInteger)GetTotalBytesReceivedWithOutNewTotalBytesReceived:(NSMutableString*)newtotalbytesreceived;
-(NSInteger)GetTotalPacketsSentWithOutNewTotalPacketsSent:(NSMutableString*)newtotalpacketssent;
-(NSInteger)GetTotalPacketsReceivedWithOutNewTotalPacketsReceived:(NSMutableString*)newtotalpacketsreceived;
-(NSInteger)GetActiveConnectionWithNewActiveConnectionIndex:(NSString*)newactiveconnectionindex OutNewActiveConnDeviceContainer:(NSMutableString*)newactiveconndevicecontainer OutNewActiveConnectionServiceID:(NSMutableString*)newactiveconnectionserviceid;

@end
