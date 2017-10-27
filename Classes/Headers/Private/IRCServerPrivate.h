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

#import "IRCServer.h"

NS_ASSUME_NONNULL_BEGIN

@interface IRCServer ()
/* IRCClient retains a copy of the active IRCServer instance.
 When the -serverList in IRCClientConfig is modified, 
 any servers that are removed will have their keychain 
 items destroyed. We do not want to destroy the keychain
 items for the IRCServer instance that IRCClient has a copy
 of, so the -destroyKeychainItemsDuringDealloc flag is used.
 This tells the IRCServer instance to hold onto the keychain
 item until there is no longer a reference to it. */
@property (nonatomic, assign) BOOL destroyKeychainItemsDuringDealloc;

- (void)writeServerPasswordToKeychain;

- (void)destroyServerPasswordKeychainItem;

/* Deprecated */
- (void)writeItemsToKeychain TEXTUAL_DEPRECATED("Use one or more -write*ToKeychain methods to avoid confusion on what is actually written.");
- (void)destroyKeychainItems TEXTUAL_DEPRECATED("Use one or more -destroy*KeychainItem methods to avoid confusion on what is actually destroyed.");
@end

NS_ASSUME_NONNULL_END
