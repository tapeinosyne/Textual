/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2017 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
      names of its contributors may be used to endorse or promote products 
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "ICLInlineContentModuleInternal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ICLInlineContentModule (ICLInlineContentModulePrivate)

- (instancetype)initWithPayload:(ICLPayloadMutable *)payload completionBlock:(ICLInlineContentModuleCompletionBlock)completionBlock
{
	NSParameterAssert(payload != nil);
	NSParameterAssert(completionBlock != nil);

	if ((self = [super init])) {
		self->_payload = payload;

		self->_completionBlock = completionBlock;

		return self;
	}

	return nil;
}

- (nullable NSURL *)templateURL
{
	return nil;
}

- (nullable GRMustacheTemplate *)template
{
	NSURL *templateURL = self.templateURL;

	if (templateURL == nil || templateURL.isFileURL == NO) {
		return nil;
	}

	NSError *templateLoadError;

	GRMustacheTemplate *template = [GRMustacheTemplate templateFromContentsOfURL:templateURL error:&templateLoadError];

	if (template == nil) {
		LogToConsoleError("Failed to load template '%@': %@",
			  templateURL, templateLoadError.localizedDescription);
	}

	return template;
}

- (void)mergePropertiesIntoPayload
{
	NSArray *scriptResources = self.scriptResources;

	if (scriptResources) {
		self.payload.scriptResources = scriptResources;
	}

	NSArray *styleResources = self.styleResources;

	if (styleResources) {
		self.payload.styleResources = styleResources;
	}

	NSString *entrypoint = self.entrypoint;

	if (entrypoint) {
		self.payload.entrypoint = entrypoint;
	}
}

- (NSError *)genericValidationFailedError
{
	return [ICLInlineContentModule genericValidationFailedError];
}

+ (NSError *)genericValidationFailedError
{
	static NSError *error = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		error =
		[NSError errorWithDomain:ICLInlineContentErrorDomain
							code:1003
						userInfo:@{
			NSLocalizedDescriptionKey : @"Validation failed"
		}];
	});

	return error;
}

#pragma mark -
#pragma mark JSON

- (NSURLSessionDataTask *)requestJSONObject:(NSString *)objectKey ofType:(Class)objectType inHierarchy:(nullable NSArray<NSString *> *)hierarchy fromURL:(NSURL *)url completionBlock:(void (^)(id _Nullable object))completionBlock
{
	NSParameterAssert(objectKey != nil);
	NSParameterAssert(objectType != NULL);
	NSParameterAssert(url != nil);
	NSParameterAssert(completionBlock != nil);

	return [self requestJSONDataFromURL:url completionBlock:^(BOOL success, NSDictionary<NSString *,id> * _Nullable data) {
		/* Return nothing if underlying request failed. */
		if (success == NO) {
			completionBlock(nil);

			return;
		}

		/* Traverse hiearchy */
		/* hierarchy is the path we will traverse to find objectKey.
		 All keys assigned to hierarchy are expected to be a dictionary.
		 If a key in hierarchy does not exist or is not a dictionary,
		 then the request exits. */
		NSDictionary *currentContext = data;

		if (hierarchy) {
			for (NSString *hierarchyKey in hierarchy) {
				id hierarchyContext = [currentContext dictionaryForKey:hierarchyKey];

				/* Return nothing if we cannot go deeper. */
				if (hierarchyContext == nil) {
					completionBlock(nil);

					return;
				}

				currentContext = hierarchyContext;
			}
		}

		/* Get object value and check type */
		id objectValue = currentContext[objectKey];

		/* Object is not a type we are interested in */
		if ([objectValue isKindOfClass:objectType] == NO) {
			completionBlock(nil);

			return;
		}

		/* Object is a type we are interested in */
		completionBlock(objectValue);
	}];
}

- (NSURLSessionDataTask *)requestJSONObject:(NSString *)objectKey ofType:(Class)objectType inHierarchy:(nullable NSArray<NSString *> *)hierarchy fromAddress:(NSString *)address completionBlock:(void (^)(id _Nullable object))completionBlock
{
	NSParameterAssert(objectKey != nil);
	NSParameterAssert(objectType != NULL);
	NSParameterAssert(address != nil);
	NSParameterAssert(completionBlock != nil);

	NSURL *url = [NSURL URLWithString:address];

	return [self requestJSONObject:objectKey ofType:objectType inHierarchy:hierarchy fromURL:url completionBlock:completionBlock];
}

- (NSURLSessionDataTask *)requestJSONDataFromURL:(NSURL *)url completionBlock:(void (^)(BOOL success, NSDictionary<NSString *, id> * _Nullable data))completionBlock
{
	NSParameterAssert(url != nil);
	NSParameterAssert(completionBlock != nil);

	NSURLSession *session = [NSURLSession sharedSession];

	NSURLSessionDataTask *sessionTask =
	[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		/* Report error if data is nil or we have a non-OK response from server. */
		if (data == nil || ((NSHTTPURLResponse *)response).statusCode != 200) {
			if (error) {
				LogToConsoleError("Request failed with error: %@",
					 error.localizedDescription);
			}

			completionBlock(NO, nil);

			return;
		}

		/* Decode JSON data */
		NSError *decodedJsonError;

		NSDictionary *decodedJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodedJsonError];

		if (decodedJson == nil) {
			LogToConsoleError("Failed to decode response: %@",
				decodedJsonError.localizedDescription);

			completionBlock(NO, nil);

			return;
		}

		if ([decodedJson isKindOfClass:[NSDictionary class]] == NO) {
			completionBlock(NO, nil);

			return;
		}

		/* Post JSON data */
		completionBlock(YES, decodedJson);
	}];

	[sessionTask resume];

	return sessionTask;
}

- (NSURLSessionDataTask *)requestJSONDataFromAddress:(NSString *)address completionBlock:(void (^)(BOOL success, NSDictionary<NSString *, id> * _Nullable data))completionBlock
{
	NSParameterAssert(address != nil);
	NSParameterAssert(completionBlock != nil);

	NSURL *url = [NSURL URLWithString:address];

	return [self requestJSONDataFromURL:url completionBlock:completionBlock];
}

@end

NS_ASSUME_NONNULL_END
