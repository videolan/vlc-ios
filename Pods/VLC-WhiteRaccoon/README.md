### Changes against the original implementation

* Improved memory usage
* Files are downloaded to a local file instead of dumping everything in memory if requested
* Progress reports via delegation
* Added an interface to access a full file URL within a session
* Improved support for ftpd included within OS X 10.8 and later
* Added an interface to download files with a full URL without the need to create a session first
* Improved dispatch handling (dropping support for iOS 5)
* Stability improvements



### General notes

You can use WhiteRaccoon to interact with FTP servers in one of two ways: either make a simple request and send it right away to the FTP server or add several requests to a queue and the queue will send them one by one in the order in which they were added.


WhiteRaccoon supports the following FTP operations:

*   Download file
*   Upload file (if the file is already on the server the delegate 
    will be asked if the file should be overwritten)
*   Delete file
*   Delete directory (only if the directory is empty)
*   Create directory
*   List directory contents (returns an array of dictionaries, each dictionary
    has the keys described [here](http://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFFTPStreamRef/Reference/reference.html#//apple_ref/doc/c_ref/kCFFTPResourceMode))


IMPORTANT: In order for the library to compile and run, you have to include **CFNetwork** framework into your project.



### Simple usage


#### Download file

        - download
        {

            //we don't autorelease the object so that it will be around when the callback gets called
            //this is not a good practice, in real life development you should use a retain property to store a reference to the request
            WRRequestDownload * downloadFile = [[WRRequestDownload alloc] init];
            downloadFile.delegate = self;
            
            //the path needs to be absolute to the FTP root folder.
            //full URL would be ftp://xxx.xxx.xxx.xxx/space.jpg
            downloadFile.path = @"/space.jpg";

            //for anonymous login just leave the username and password nil
            downloadFile.hostname = @"xxx.xxx.xxx.xxx";
            downloadFile.username = @"myuser";
            downloadFile.password = @"mypass";

            //we start the request
            [downloadFile start];

        }

        -(void) requestCompleted:(WRRequest *) request{
            //called after 'request' is completed successfully
            NSLog(@"%@ completed!", request);

            //we cast the request to download request
            WRRequestDownload * downloadFile = (WRRequestDownload *)request;

            //we get the image from the data
            UIImage * image = [UIImage imageWithData:downloadFile.receivedData];
        }

        -(void) requestFailed:(WRRequest *) request{
            //called after 'request' ends in error
            //we can print the error message
            NSLog(@"%@", request.error.message);
        }


#### Upload file

        - upload
        {

            //the upload request needs the input data to be NSData 
            //so we first convert the image to NSData
            UIImage * ourImage = [UIImage imageNamed:@"space.jpg"];
            NSData * ourImageData = UIImageJPEGRepresentation(ourImage, 100);


            //we create the upload request
            //we don't autorelease the object so that it will be around when the callback gets called
            //this is not a good practice, in real life development you should use a retain property to store a reference to the request
            WRRequestUpload * uploadImage = [[WRRequestUpload alloc] init];
            uploadImage.delegate = self;

            //for anonymous login just leave the username and password nil
            uploadImage.hostname = @"xxx.xxx.xxx.xxx";
            uploadImage.username = @"myuser";
            uploadImage.password = @"mypass";
            
            //we set our data
            uploadImage.sentData = ourImageData;
            
            //the path needs to be absolute to the FTP root folder.
            //full URL would be ftp://xxx.xxx.xxx.xxx/space.jpg
            uploadImage.path = @"/space.jpg";

            //we start the request
            [uploadImage start];

        }

        -(void) requestCompleted:(WRRequest *) request{

            //called if 'request' is completed successfully
            NSLog(@"%@ completed!", request);

        }

        -(void) requestFailed:(WRRequest *) request{

            //called after 'request' ends in error
            //we can print the error message
            NSLog(@"%@", request.error.message);

        }

        -(BOOL) shouldOverwriteFileWithRequest:(WRRequest *)request {

            //if the file (ftp://xxx.xxx.xxx.xxx/space.jpg) is already on the FTP server,the delegate is asked if the file should be overwritten 
            //'request' is the request that intended to create the file
            return YES;

        }


#### List directory contents

The file dictionary has several keys that describe most of the properties a file can have, from name to size. For a complete list of keys that the file dictionary has have a look [here](http://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFFTPStreamRef/Reference/reference.html#//apple_ref/doc/c_ref/kCFFTPResourceMode)

        - listDirectoryContents
        {

            //we don't autorelease the object so that it will be around when the callback gets called
            //this is not a good practice, in real life development you should use a retain property to store a reference to the request
            WRRequestListDirectory * listDir = [[WRRequestListDirectory alloc] init];
            listDir.delegate = self;
            
            
            //the path needs to be absolute to the FTP root folder.
            //if we want to list the root folder we let the path nil or /
            //full URL would be ftp://xxx.xxx.xxx.xxx/
            listDir.path = @"/";

            listDir.hostname = @"xxx.xxx.xxx.xxx";
            listDir.username = @"myuser";
            listDir.password = @"mypass";


            [listDir start];

        }

        -(void) requestCompleted:(WRRequest *) request{

            //called after 'request' is completed successfully
            NSLog(@"%@ completed!", request);

            //we cast the request to list request
            WRRequestListDirectory * listDir = (WRRequestListDirectory *)request;

            //we print each of the files name
            for (NSDictionary * file in listDir.filesInfo) {
                NSLog(@"%@", [file objectForKey:(id)kCFFTPResourceName]);            
            }

        }

        -(void) requestFailed:(WRRequest *) request{
        
            //called if 'request' ends in error
            //we can print the error message
            NSLog(@"%@", request.error.message);

        }


#### Delete file or directory

        - deleteFileOrDirectory
        {

            //we don't autorelease the object so that it will be around when the callback gets called
            //this is not a good practice, in real life development you should use a retain property to store a reference to the request
            WRRequestDelete * deleteDir = [[WRRequestDelete alloc] init];

            //the path needs to be absolute to the FTP root folder.
            //if we are want to delete a directory we have to end the path with / and make sure the directory is empty
            //full URL would be ftp://xxx.xxx.xxx.xxx/dummyDir/
            deleteDir.path = @"/dummyDir/";

            deleteDir.hostname = @"xxx.xxx.xxx.xxx";
            deleteDir.username = @"myuser";
            deleteDir.password = @"mypass";

            //we start the request
            [deleteDir start];

        }


#### Create directory

        - createDirectory
        {

            //we don't autorelease the object so that it will be around when the callback gets called
            //this is not a good practice, in real life development you should use a retain property to store a reference to the request
            WRRequestCreateDirectory * createDir = [[WRRequestCreateDirectory alloc] init];

            //we set self as delegate, we must implement WRRequestDelegate
            createDir.delegate = self;

            //the path needs to be absolute to the FTP root folder.
            //full URL would be ftp://xxx.xxx.xxx.xxx/dummyDir/
            createDir.path = @"/dummyDir/";

            createDir.hostname = @"xxx.xxx.xxx.xxx";
            createDir.username = @"myuser";
            createDir.password = @"mypass";

            //we start the request
            [createDir start];

        }

        -(void) requestCompleted:(WRRequest *) request{

            //called if 'request' is completed successfully
            NSLog(@"%@ completed!", request);

        }

        -(void) requestFailed:(WRRequest *) request{

            //called if 'request' ends in error
            //we can print the error message
            NSLog(@"%@", request.error.message);

        }







### Queue usage

Here is how you can use a queue request to create a directory and then add an image in it.

        - upload
        {

            //we alloc and init the our request queue
            //we don't autorelease the object so that it will be around when the callback gets called
            WRRequestQueue * requestsQueue = [[WRRequestQueue alloc] init];

            //we set the delegate to self
            requestsQueue.delegate = self;

            //we set the credentials and hostname
            //every request added to the queue will use them if it doesn't have its own credentials and/or hostname
            //for anonymous login just leave the username and password nil
            requestsQueue.hostname = @"xxx.xxx.xxx.xxx";
            requestsQueue.username = @"myuser";
            requestsQueue.password = @"mypass";


            //and now, we start to create our requests and add them to the queue
            //the requests will be executed in the order in which they were added, one by one


            //we first create a directory
            //we can safely autorelease the request object because the queue takes ownership of it in addRequest: method
            WRRequestCreateDirectory * createDir = [[[WRRequestCreateDirectory alloc] init] autorelease];

            //the path needs to be absolute to the FTP root folder.
            //full URL would be ftp://xxx.xxx.xxx.xxx/dummyDir/
            createDir.path = @"/dummyDir/";

            [requestsQueue addRequest:createDir];


            //then we upload the file in our newly created directory
            //the upload request needs the input data to be NSData 
            //so we first convert the image to NSData
            UIImage * ourImage = [UIImage imageNamed:@"space.jpg"];
            NSData * ourImageData = UIImageJPEGRepresentation(ourImage, 100);


            //we create the upload request
            WRRequestUpload * uploadImage = [[[WRRequestUpload alloc] init] autorelease];
            uploadImage.sentData = ourImageData;


            //we put the file in the directory we created with the previous request
            //the path needs to be absolute to the FTP root folder.
            //full URL would be ftp://xxx.xxx.xxx.xxx/dummyDir/image.jpg
            uploadImage.path = @"/dummyDir/image.jpg";


            [requestsQueue addRequest:uploadImage];

            //we start the request queue
            [requestsQueue start];

        }

        -(void) queueCompleted:(WRRequestQueue *)queue {

            //this will get called when all the requests are done
            //even if one or more requests end in error, this will still be called after the rest are completed
            NSLog(@"Done.");

        }

        -(void) requestCompleted:(WRRequest *) request{

            //called after 'request' is completed successfully
            NSLog(@"%@ completed!", request);

        }

        -(void) requestFailed:(WRRequest *) request{

            //called after 'request' ends in error
            //we can print the error message
            NSLog(@"%@", request.error.message);

        }

        -(BOOL) shouldOverwriteFileWithRequest:(WRRequest *)request {

            //if the file (ftp://xxx.xxx.xxx.xxx/dummyDir/image.jpg) is already on the FTP server,the delegate is asked if the file should be overwritten 
            //'request' is the request that intended to create the file
            return YES;

        }
