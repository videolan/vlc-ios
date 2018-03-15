GRKArrayDiff
===========
Given two NSArrays, a previous and a current, GRKArrayDiff will report all deletions,
insertions, moves, and modifications. This is specifically targeted for array backed data
models which are used to support Table Views and Collection Views, but is generally
applicable as well.

### Installing

If you're using [CocoPods](http://cocopods.org) it's as simple as adding this to your
`Podfile`:

	pod 'GRKArrayDiff'

otherwise, simply add the contents of the `GRKArrayDiff` subdirectory to your
project.

### Documentation

To use, simply import `GRKArrayDiff.h`:

    #import "GRKArrayDiff.h"

Then alloc and init a new instance, passing in the previous array, the new array, and two
blocks. The `identityBlock` is responsible for uniquely identifying the given object while
the `modifiedBlock` is responsible for reporting if the given `currentObj` object is to be
considered as modified.

	GRKArrayDiff *diff = [[GRKArrayDiff alloc] initWithPreviousArray:previousArray currentArray:currentArray identityBlock:^NSString *(id obj) {
		return [obj identifier];
	} modifiedBlock:^BOOL(id  _Nonnull previousObj, id  _Nonnull currentObj) {
		return [[currentObj identifier] isEqualToString:@"five"] ||
		[[currentObj identifier] isEqualToString:@"three"] ||
		[[currentObj identifier] isEqualToString:@"zero"] ||
		[[currentObj identifier] isEqualToString:@"one"];
	}];

Once created, the instance's four properties (`deletions`, `insertions`, `moves`, and
`modifications`) will be populated with NSSets of `GRKArrayDiffInfo` objects which
describe the changes to the elements between the previous and current arrays.

Typical iOS table view update usage would look something like this:

    //Save the current data model for comparison
    NSArray *oldDataModel = self.dataModel;

    //Update our data model with the latest
    self.dataModel = [self updateDataModel];

    //Get differences in data model
    GRKArrayDiff *diff = [[GRKArrayDiff alloc] initWithPreviousArray:oldDataModel currentArray:self.dataModel identityBlock:^NSString *(id obj) {
        NSString *identifier = nil;
        if ([obj conformsToProtocol:@protocol(MyType)])
        {
            id <MyType> myObj = (id <MyType>)obj;
            identifier = [myObj uuid];
        }
        return identifier;
    } modifiedBlock:^BOOL(id  _Nonnull previousObj, id  _Nonnull currentObj) {
        BOOL modified = currentObj != nil && [modificationSet containsObject:currentObj];
        return modified;
    }];
    
    //Update the UI with the changes
    [diff updateTableView:self.tableView section:0 animation:animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone completion:nil];

Additional documentation is available in `GRKArrayDiff.h` and example usage
can be found in the `GRKArrayDiffTest.m`.

#### Disclaimer and Licence

* I have made use of hashing code from [https://github.com/levigroker/HashBuilder](https://github.com/levigroker/HashBuilder)
* Inspiration for table view updates taken from [TLIndexPathTools](https://github.com/wtmoose/TLIndexPathTools)
* This work is licensed under the [Creative Commons Attribution 3.0 Unported License](http://creativecommons.org/licenses/by/3.0/).
  Please see the included LICENSE.txt for complete details.

#### About

A professional iOS engineer by day, my name is Levi Brown. Authoring a blog
[grokin.gs](http://grokin.gs), I am reachable via:

Twitter [@levigroker](https://twitter.com/levigroker)  
Email [levigroker@gmail.com](mailto:levigroker@gmail.com)  

Your constructive comments and feedback are always welcome.
