//
//  BoxAuthorizationViewController.m
//  BoxSDK
//
//  Created on 2/20/13.
//  Copyright (c) 2013 Box. All rights reserved.
//

#import "BoxAuthorizationViewController.h"
#import "BoxLog.h"

#define BOX_SSO_SERVER_TRUST_ALERT_TAG (1)
#define BOX_SSO_CREDENTIALS_ALERT_TAG (2)

@interface BoxAuthorizationViewController ()

@property (nonatomic, readwrite, strong) NSURL *authorizationURL;
@property (nonatomic, readwrite, strong) NSString *redirectURIString;
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite, strong) NSURLResponse *connectionResponse;
@property (nonatomic, readwrite, strong) NSMutableData *connectionData;
@property (nonatomic, readwrite, strong) NSURLAuthenticationChallenge *authenticationChallenge;
@property (nonatomic, readwrite, assign) BOOL connectionIsTrusted;
@property (nonatomic, readwrite, assign) BOOL hasLoadedLoginPage;

@property (nonatomic, readwrite, strong) NSArray *preexistingCookies;
@property (nonatomic, readwrite, assign) NSHTTPCookieAcceptPolicy preexistingCookiePolicy;

- (void)cancel:(id)sender;
- (void)completeServerTrustAuthenticationChallenge:(NSURLAuthenticationChallenge *)authenticationChallenge shouldTrust:(BOOL)trust;
- (void)clearCookies;

@end

@implementation BoxAuthorizationViewController

@synthesize delegate = _delegate;
@synthesize authorizationURL = _authorizationURL;
@synthesize redirectURIString = _redirectURIString;
@synthesize connection = _connection;
@synthesize connectionResponse = _connectionResponse;
@synthesize connectionData = _connectionData;
@synthesize authenticationChallenge = _authenticationChallenge;
@synthesize connectionIsTrusted = _connectionIsTrusted;
@synthesize hasLoadedLoginPage = _hasLoadedLoginPage;
@synthesize preexistingCookies = _preexistingCookies;
@synthesize preexistingCookiePolicy = _preexistingCookiePolicy;

- (id)initWithAuthorizationURL:(NSURL *)authorizationURL redirectURI:(NSString *)redirectURI
{
	self = [super init];
	if (self != nil)
	{
		_authorizationURL = authorizationURL;
		_redirectURIString = redirectURI;
		_connectionData = [[NSMutableData alloc] init];
		_connectionIsTrusted = NO;
		_hasLoadedLoginPage = NO;

		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];

		NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		_preexistingCookies = [[cookieStorage cookies] copy];
		_preexistingCookiePolicy = [cookieStorage cookieAcceptPolicy];
	}
	
	return self;
}

- (void)dealloc
{
	[self clearCookies];
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:_preexistingCookiePolicy];
}

- (void)loadView
{
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

	UIWebView *webView = [[UIWebView alloc] init];
	[webView setScalesPageToFit:YES];
	webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	webView.delegate = self;

	self.view = webView;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	if (self.hasLoadedLoginPage == NO)
	{
		NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.authorizationURL];

		UIWebView *webView = (UIWebView *)self.view;
		[webView loadRequest:request];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	UIWebView *webView = (UIWebView *)self.view;
	[webView stopLoading];

	[self.connection cancel];
}

#pragma mark - Actions

- (void)cancel:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(authorizationViewControllerDidCancel:)])
	{
		[self.delegate authorizationViewControllerDidCancel:self];
	}
}

#pragma mark - Private helper methods

- (void)completeServerTrustAuthenticationChallenge:(NSURLAuthenticationChallenge *)authenticationChallenge shouldTrust:(BOOL)trust
{
	if (trust)
	{
		BOXLog(@"Trust the host.");
		SecTrustRef serverTrust = [[authenticationChallenge protectionSpace] serverTrust];
		NSURLCredential *serverTrustCredential = [NSURLCredential credentialForTrust:serverTrust];
		[[authenticationChallenge sender] useCredential:serverTrustCredential
							 forAuthenticationChallenge:authenticationChallenge];
	}
	else
	{
		BOXLog(@"Do not trust the host. Presenting an error to the user.");
		UIAlertView *loginFailureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login Failure", @"Alert view title: Title for failed SSO login due to authentication issue")
																		message:NSLocalizedString(@"Could not complete login because the SSO server is untrusted. Please contact your administrator for more information.", @"Alert view message: message for failed SSO login due to untrusted (for example: self signed) certificate")
																	   delegate:nil
															  cancelButtonTitle:NSLocalizedString(@"OK", @"Button title: Dismiss the alert view")
															  otherButtonTitles:nil];

		[loginFailureAlertView show];
	}
}

- (void)clearCookies
{
	BOXLog(@"Attempt to clear cookies");
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [[cookieStorage cookies] copy];
	for (NSHTTPCookie *cookie in cookies)
	{
		if ([self.preexistingCookies containsObject:cookie] == NO)
		{
			[cookieStorage deleteCookie:cookie];
			BOXLog(@"Clearing cookie with domain %@, name %@", cookie.domain, cookie.name);
		}
	}
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	BOXLog(@"Web view should start request %@ with navigation type %ld", request, (long)navigationType);
	BOXLog(@"Request Headers \n%@", [request allHTTPHeaderFields]);

	// Before we proceed with handling this request, check if it's about:blank - if it is, do not attempt to load it.
	// Background: We've run into a scenario where an admin included a support help-desk plugin on their SSO page
	// which would (probably erroneously) first load about:blank, then attempt to load its icon. The web view would
	// fail to load about:blank, which would cause the whole page to not appear. So we realized that we can and should
	// generally protect against loading about:blank.
	if ([request.URL isEqual:[NSURL URLWithString:@"about:blank"]])
	{
		return NO;
	}

	[self.delegate authorizationViewControllerDidStartLoading:self];

	if (self.hasLoadedLoginPage == NO)
	{
		self.hasLoadedLoginPage = YES;
	}

	// Figure out whether the scheme of this request is the redirect scheme used at the end of the authentication process
	BOOL requestIsForLoginRedirectScheme = NO;
	if ([self.redirectURIString length] > 0)
	{
		requestIsForLoginRedirectScheme = [[[request URL] scheme] isEqualToString:[[NSURL URLWithString:self.redirectURIString] scheme]];
	}

	if (requestIsForLoginRedirectScheme)
	{
		if ([self.delegate respondsToSelector:@selector(authorizationViewController:shouldLoadReceivedOAuth2RedirectRequest:)])
		{
			return [self.delegate authorizationViewController:self shouldLoadReceivedOAuth2RedirectRequest:request];
		}
	}
	else if (self.connectionIsTrusted == NO)
	{
		BOXLog(@"Was not authenticated, launching URLConnection and not loading the request in the web view");
		self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		BOXLog(@"URLConnection is %@", self.connection);
		return NO;
	}

	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	BOXLogFunction();
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	BOXLog(@"Web view %@ did fail load with error %@", webView, error);

	// The following error scenarios are benign and do not actually signify that loading the login page has failed:
	// 1. WebKitErrorDomain > WebKitErrorFrameLoadInterruptedByPolicyChange - Indicates that a frame load was interrupted by a policy change.
	//  These constants seem to only be declared for OS X in the WebKit framework, but we're seeing them in iOS.
	// 2. NSURLErrorDomain > NSURLErrorCancelled - Returned when an asynchronous load is canceled. A Web Kit framework delegate will receive this error when it performs a cancel operation on a loading resource. Note that an NSURLConnection or NSURLDownload delegate will not receive this error if the download is canceled.
	// 3. The load attempt was for an iframe rather than the full page

	BOOL ignoreError = NO;
	//NOTE: WebKitErrorDomain and WebKitErrorFrameLoadInterruptedByPolicyChange are only defined on OS X in the WebKit framework
	// however the error is occuring on iOS, thus we use the values directly in the conditional below.
	if ([[error domain] isEqualToString:@"WebKitErrorDomain"] && [error code] == 102)
	{
		BOXLog(@"Ignoring error with code 102 (WebKitErrorFrameLoadInterruptedByPolicyChange)");
		ignoreError = YES;
	}
	else if ([[error domain] isEqualToString:NSURLErrorDomain] && [error code] == NSURLErrorCancelled)
	{
		BOXLog(@"Ignoring error with code URLErrorCancelled");
		ignoreError = YES;
	}
	else if ([[error domain] isEqualToString:NSURLErrorDomain])
	{
		// Check if its just an iframe loading error
		// Note - The suggested key for checking the failed URL is NSURLErrorFailingURLStringErrorKey.
		// However, in testing, this was not found in iOS 5, and only the deprecated value NSErrorFailingURLStringKey
		// was used.  We use the string value instead of the constant as the constant gives a (presumably erronous)
		// deprecated (in iOS 4) warning.
		NSString *requestURLString = [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey];
		if ([requestURLString length] == 0)
		{
			requestURLString = [[error userInfo] objectForKey:@"NSErrorFailingURLStringKey"];
		}
		
		BOXLog(@"Checking if error is due to an iframe request.");
		BOXLog(@"Request URL is %@ while main document URL is %@", requestURLString, [webView.request mainDocumentURL]);
		
		BOOL isMainDocumentURL = [requestURLString isEqualToString:[[webView.request mainDocumentURL] absoluteString]];
		if (isMainDocumentURL == NO)
		{
			// If the failing URL is not the main document URL, then the load error is in an iframe and can be ignored
			BOXLog(@"Ignoring error as the load failure is in an iframe");
			ignoreError = YES;
		}
	}

	if (ignoreError == NO)
	{
		BOXLog(@"Presenting error");
		[self.delegate authorizationViewControllerDidFinishLoading:self];
		// The error is usually in HTML to be shown to the user.
		[webView loadHTMLString:[error localizedDescription] baseURL:nil];
	}
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	BOXLogFunction();
	[self.delegate authorizationViewControllerDidFinishLoading:self];
	self.connectionIsTrusted = NO;
}

#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	BOXLog(@"connection %@ did receive authentication challenge %@", connection, challenge);
	if ([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		BOXLog(@"Server trust authentication challenge");
		SecTrustResultType trustResult = kSecTrustResultOtherError;
		OSStatus status = SecTrustEvaluate([[challenge protectionSpace] serverTrust], &trustResult);
		
		BOOL requestUserConfirmation = NO;
		if (status == errSecSuccess)
		{
			switch (trustResult)
			{
				case kSecTrustResultInvalid:
					// Invalid setting or result. Usually, this result indicates that the SecTrustEvaluate function did not complete successfully.
					requestUserConfirmation = YES;
					break;
				case kSecTrustResultProceed:
					// The user indicated that you may trust the certificate for the purposes designated in the specified policies. This value may be returned by the SecTrustEvaluate function or stored as part of the user trust settings. In the Keychain Access utility, this value is termed “Always Trust.”
					// Do not request user confirmation, it is safe to proceed.
					break;
				case kSecTrustResultDeny:
					// The user specified that the certificate should not be trusted. This value may be returned by the SecTrustEvaluate function or stored as part of the user trust settings. In the Keychain Access utility, this value is termed “Never Trust.”
					requestUserConfirmation = YES;
					break;
				case kSecTrustResultUnspecified:
					// The user did not specify a trust setting. This value may be returned by the SecTrustEvaluate function or stored as part of the user trust settings. In the Keychain Access utility, this value is termed “Use System Policy.” This is the default user setting.
					// Do not request user confirmation, it is safe to proceed.
					break;
				case kSecTrustResultRecoverableTrustFailure:
					// Trust denied; retry after changing settings. For example, if trust is denied because the certificate has expired, you can ask the user whether to trust the certificate anyway. If the user answers yes, then use the SecTrustSettingsSetTrustSettings function to set the user trust setting to kSecTrustResultProceed and call SecTrustEvaluate again. This value may be returned by the SecTrustEvaluate function but not stored as part of the user trust settings.
					requestUserConfirmation = YES;
					break;
				case kSecTrustResultFatalTrustFailure:
					// Trust denied; no simple fix is available. For example, if a certificate cannot be verified because it is corrupted, trust cannot be established without replacing the certificate. This value may be returned by the SecTrustEvaluate function but not stored as part of the user trust settings.
					requestUserConfirmation = YES;
					break;
				case kSecTrustResultOtherError:
					// A failure other than that of trust evaluation; for example, an internal failure of the SecTrustEvaluate function. This value may be returned by the SecTrustEvaluate function but not stored as part of the user trust settings.
					requestUserConfirmation = YES;
					break;
				default:
					break;
			}
		}
		else
		{
			// The SecTrustEvaluate method failed
			BOXLog(@"Sec trust evaluate failed to establish a value, so prompt the user.");
			requestUserConfirmation = YES;
		}

		if (requestUserConfirmation)
		{
			self.authenticationChallenge = challenge;
			UIAlertView *serverTrustAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Verify Server Identity", @"Alert view title: title for SSO server trust challenge")
																		   message:[NSString stringWithFormat:NSLocalizedString(@"Box cannot verify the identity of \"%@\". Would you like to continue anyway?", @"Alert view message: Message for SSO server trust challenge, giving the user the host of the server who's identity cannot be verified."), [[challenge protectionSpace] host]]
																		  delegate:self
																 cancelButtonTitle:NSLocalizedString(@"Cancel", @"Button title: cancel action")
																 otherButtonTitles:NSLocalizedString(@"Continue", @"Alert view button: button title for when the user would like to continue with their action"), nil];
			serverTrustAlertView.tag = BOX_SSO_SERVER_TRUST_ALERT_TAG;
			[serverTrustAlertView show];
		}
		else
		{
			// By default, allow a certificate if its status was evaluated successfully and the result is
			// that it should be trusted
			BOOL shouldTrustServer = (status == errSecSuccess && (trustResult == kSecTrustResultProceed || trustResult == kSecTrustResultUnspecified));
			[self completeServerTrustAuthenticationChallenge:challenge shouldTrust:shouldTrustServer];
		}
	}
	else
	{
		BOXLog(@"Authentication challenge of type %@", [[challenge protectionSpace] authenticationMethod]);

		// Handle the authentication challenge
		// (certificate-based, among other methods, is not currently supported)
		if ([challenge previousFailureCount] > 0)
		{
			BOXLog(@"Have %ld previous failures", (long)[challenge previousFailureCount]);
			[[challenge sender] cancelAuthenticationChallenge:challenge];
			self.connection = nil;
			self.connectionIsTrusted = NO;

			UIAlertView *loginFailureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login Failure", @"Alert view title: Title for failed SSO login due to authentication issue")
																			message:NSLocalizedString(@"Unable to log in. Please check your username and password and try again.", @"Alert view message: message for failed SSO login due bad username or password")
																		   delegate:nil
																  cancelButtonTitle:NSLocalizedString(@"OK", @"Button title: Dismiss the alert view")
																  otherButtonTitles:nil];
			BOXLog(@"Returning due to bad password");
			[loginFailureAlertView show];
		}
		else
		{
			// For certificate based auth, try the default handling
			if ([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodClientCertificate])
			{
				BOXLog(@"Client certificate authentication challenge, not currently supported, trying the default handling");
				[[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
			}
			else
			{
				// Otherwise assume the challenge should be handled the same as HTTP Basic Authentication
				BOXLog(@"Presenting modal username and password window");

				self.authenticationChallenge = challenge;

				// Create the alert view
				UIAlertView *challengeAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"This page requires you to log in", @"Alert view title: title for SSO authentication challenge")
																			 message:nil
																			delegate:self
																   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Button title: cancel action")
																   otherButtonTitles:NSLocalizedString(@"Submit", @"Alert view button: submit button for SSO authentication challenge"), nil];
				challengeAlertView.tag = BOX_SSO_CREDENTIALS_ALERT_TAG;
				challengeAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
				// Change the login text field's placeholder text to Username (it defaults to Login).
				[[challengeAlertView textFieldAtIndex:0] setPlaceholder:NSLocalizedString(@"Username", @"Alert view text placeholder: Placeholder for where to enter user name for SSO authentication challenge")];
				[challengeAlertView show];
			}
		}
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	BOXLog(@"Connection %@ did fail with error %@", connection, error);
	if ([error code] != NSURLErrorUserCancelledAuthentication)
	{
		self.connection = nil;
		self.connectionResponse = nil;
		self.connectionIsTrusted = NO;

		UIAlertView *loginFailureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login Failure", @"Alert view title: Title for failed SSO login due to authentication issue")
																		message:[error localizedDescription]
																	   delegate:nil
															  cancelButtonTitle:NSLocalizedString(@"OK", @"Button title: Dismiss the alert view")
															  otherButtonTitles:nil];
		[loginFailureAlertView show];

		[self.delegate authorizationViewControllerDidFinishLoading:self];
	}
}

#pragma mark - NSURLConnectionDataDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	BOXLog(@"Connection %@ did receive response %@", connection, response);
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
	{
		BOXLog(@"HTTP Headers were: %@", [(NSHTTPURLResponse *)response allHeaderFields]);
	}
	self.connectionResponse = response;
	[self.connectionData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	BOXLog(@"Connection %@ did receive %lu bytes of data", connection, (unsigned long)[data length]);
	[self.connectionData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	BOXLog(@"Connection %@ did finish loading. Requesting that the webview load the data (%lu bytes) with reponse %@", connection, (unsigned long)[self.connectionData length], self.connectionResponse);
	self.connectionIsTrusted = YES;
	[(UIWebView *)self.view loadData:self.connectionData
							MIMEType:[self.connectionResponse MIMEType]
					textEncodingName:[self.connectionResponse textEncodingName]
							 baseURL:[self.connectionResponse URL]];

	self.connection = nil;
	self.connectionResponse = nil;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	// No cached response should be stored for the connection.
	return nil;
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	BOXLog(@"Alert view with tag %ld clicked button at index %ld", (long)alertView.tag, (long)buttonIndex);
	if (alertView.tag == BOX_SSO_CREDENTIALS_ALERT_TAG)
	{
		if (buttonIndex == alertView.cancelButtonIndex)
		{
			BOXLog(@"Cancel");
		}
		else
		{
			UITextField *usernameField = nil;
			UITextField *passwordField = nil;
			if ([alertView alertViewStyle] == UIAlertViewStyleLoginAndPasswordInput)
			{
				usernameField = [alertView textFieldAtIndex:0];
				passwordField = [alertView textFieldAtIndex:1];
			}
			else
			{
				BOXAssertFail(@"The alert view is not of login and password input style. Cannot safely extract the user's credentials.");
			}

			BOXLog(@"Submitting credential for authentication challenge %@", self.authenticationChallenge);
			self.connectionIsTrusted = YES;
			[[self.authenticationChallenge sender] useCredential:[NSURLCredential credentialWithUser:[usernameField text]
																							password:[passwordField text]
																						 persistence:NSURLCredentialPersistenceNone]
									  forAuthenticationChallenge:self.authenticationChallenge];
		}
	}
	else if (alertView.tag == BOX_SSO_SERVER_TRUST_ALERT_TAG)
	{
		BOOL trust = (buttonIndex != alertView.cancelButtonIndex);
		[self completeServerTrustAuthenticationChallenge:self.authenticationChallenge shouldTrust:trust];
	}

	// Clear out the authentication challenge in memory
	self.authenticationChallenge = nil;
}

@end
