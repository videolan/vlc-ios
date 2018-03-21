//
//  OrderedDictionary.m
//  OrderedDictionary
//
//  Created by Matt Gallagher on 19/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "OrderedDictionary.h"

NSString *DescriptionForObject(NSObject *object, id locale, NSUInteger indent)
{
    NSString *objectString;
    if ([object isKindOfClass:[NSString class]])
    {
        objectString = (NSString *)[[object retain] autorelease];
    }
    else if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)])
    {
        objectString = [(NSDictionary *)object descriptionWithLocale:locale indent:indent];
    }
    else if ([object respondsToSelector:@selector(descriptionWithLocale:)])
    {
        objectString = [(NSSet *)object descriptionWithLocale:locale];
    }
    else
    {
        objectString = [object description];
    }
    return objectString;
}

@implementation OrderedDictionary

- (instancetype)init
{
    self = [super init];
    if (self) {
        dictionary = [[NSMutableDictionary alloc] init];
        array = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithCapacity:(NSUInteger)capacity
{
    self = [super init];
    if (self != nil)
    {
        dictionary = [[NSMutableDictionary alloc] initWithCapacity:capacity];
        array = [[NSMutableArray alloc] initWithCapacity:capacity];
    }
    return self;
}

- (void)dealloc
{
    [dictionary release];
    [array release];
    [super dealloc];
}

- (id)copy
{
    return [self mutableCopy];
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    if (!dictionary[aKey])
    {
        [array addObject:aKey];
    }
    dictionary[aKey] = anObject;
}

- (void)removeObjectForKey:(id)aKey
{
    [dictionary removeObjectForKey:aKey];
    [array removeObject:aKey];
}

- (NSUInteger)count
{
    return [dictionary count];
}

- (id)objectForKey:(id)aKey
{
    return dictionary[aKey];
}

- (NSEnumerator *)keyEnumerator
{
    return [array objectEnumerator];
}

- (NSEnumerator *)reverseKeyEnumerator
{
    return [array reverseObjectEnumerator];
}

- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(NSUInteger)anIndex
{
    if (!dictionary[aKey])
    {
        [self removeObjectForKey:aKey];
    }
    [array insertObject:aKey atIndex:anIndex];
    dictionary[aKey] = anObject;
}

- (id)keyAtIndex:(NSUInteger)anIndex
{
    return array[anIndex];
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level
{
    NSMutableString *indentString = [NSMutableString string];
    NSUInteger i, count = level;
    for (i = 0;i < count;i++)
    {
        [indentString appendFormat:@"    "];
    }

    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"%@{\n", indentString];
    for (NSObject *key in self)
    {
        [description appendFormat:@"%@    %@ = %@;\n",
            indentString,
            DescriptionForObject(key, locale, level),
            DescriptionForObject(self[key], locale, level)];
    }
    [description appendFormat:@"%@}\n", indentString];
    return description;
}

@end
