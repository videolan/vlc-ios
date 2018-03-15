//Auto Generated file.
//This file is part of the upnox project.
//Copyright 2010 - 2011 Bruno Keymolen, all rights reserved.

#import <Foundation/Foundation.h>
#import "SoapAction.h"

@interface SoapActionsConfigurationManagement1 : SoapAction {
    }

//SOAP

-(NSInteger)GetSupportedDataModelsWithOutSupportedDataModels:(NSMutableString*)supporteddatamodels;
-(NSInteger)GetSupportedParametersWithStartingNode:(NSString*)startingnode SearchDepth:(NSString*)searchdepth OutResult:(NSMutableString*)result;
-(NSInteger)GetInstancesWithStartingNode:(NSString*)startingnode SearchDepth:(NSString*)searchdepth OutResult:(NSMutableString*)result;
-(NSInteger)GetValuesWithParameters:(NSString*)parameters OutParameterValueList:(NSMutableString*)parametervaluelist;
-(NSInteger)GetSelectedValuesWithStartingNode:(NSString*)startingnode Filter:(NSString*)filter OutParameterValueList:(NSMutableString*)parametervaluelist;
-(NSInteger)SetValuesWithParameterValueList:(NSString*)parametervaluelist OutStatus:(NSMutableString*)status;
-(NSInteger)CreateInstanceWithMultiInstanceName:(NSString*)multiinstancename ChildrenInitialization:(NSString*)childreninitialization OutInstanceIdentifier:(NSMutableString*)instanceidentifier OutStatus:(NSMutableString*)status;
-(NSInteger)DeleteInstanceWithInstanceIdentifier:(NSString*)instanceidentifier OutStatus:(NSMutableString*)status;
-(NSInteger)GetAttributesWithParameters:(NSString*)parameters OutNodeAttributeValueList:(NSMutableString*)nodeattributevaluelist;
-(NSInteger)SetAttributesWithNodeAttributeValueList:(NSString*)nodeattributevaluelist OutStatus:(NSMutableString*)status;
-(NSInteger)GetInconsistentStatusWithOutStateVariableValue:(NSMutableString*)statevariablevalue;
-(NSInteger)GetConfigurationUpdateWithOutStateVariableValue:(NSMutableString*)statevariablevalue;
-(NSInteger)GetCurrentConfigurationVersionWithOutStateVariableValue:(NSMutableString*)statevariablevalue;
-(NSInteger)GetSupportedDataModelsUpdateWithOutStateVariableValue:(NSMutableString*)statevariablevalue;
-(NSInteger)GetSupportedParametersUpdateWithOutStateVariableValue:(NSMutableString*)statevariablevalue;
-(NSInteger)GetAttributeValuesUpdateWithOutStateVariableValue:(NSMutableString*)statevariablevalue;

@end
