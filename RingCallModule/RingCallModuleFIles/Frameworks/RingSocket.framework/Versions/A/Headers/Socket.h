/* Caitlin 
 * Socket.h - Socket class interface
 * -------------------------------------------------------------------------
 * This file contains code written by:
 * - Daniel Fischer, <dan@gueldenland.de>
 * -------------------------------------------------------------------------
 * Copyright (c) 2001, Daniel Fischer
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions are 
 * met:
 *
 * - Redistributions of source code must retain the above copyright 
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 *
 * - Neither the name of the author nor the names of the contributors may 
 *   be used to endorse or promote products derived from this software without 
 *   specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR 
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

typedef enum { 
	SocketUninitialized,
	SocketConnected
} SocketStatus; 

/** .** Socket
 * Socket is the basic socket class. Some of its methods must be implemented
 * by subclasses, and all of them are supposed to work with any subclass.
 **/
@interface Socket : NSObject
{
	int st, sock, timeout;

	NSMutableData *buf;
	NSString *lastline;
}

/** .*** - initWithSocket
 * .= Declaration
 * <|- initWithSocket: (int)socket|>
 * .= Description
 * initializes the object with a previously opened socket.
 **/
- 		initWithSocket: (int) socket;

/** .*** - close
 * .= Declaration
 * <|- (void) close|>
 * .= Description
 * closes the associated socket. You're not supposed to re-use a Socket
 * object, but you can still use <+readLine+> and <+readBytes+> to process
 * the contents of the buffer after closing it.
 **/
- (void)	close;

/** .*** - status
 * .= Declaration
 * <|- (SocketStatus) status|>
 * .= Description
 * returns the current status of the socket, which can be one of
 * <+SocketUninitialized+>, or <+SocketConnected+>.
 **/
- (SocketStatus) status;

/** .*** - socket
 * .= Declaration
 * <|- (int) socket|>
 * .= Description
 * returns the socket being used.
 **/
- (int)		socket;

/** .*** - buffer
 * .= Declaration
 * <|- (NSMutableData *) buffer|>
 * .= Description
 * returns the <+NSMutableData+> object which is used as a buffer for
 * incoming data.
 **/

/** .*** - readLine
 * .= Declaration
 * <|- (NSString *) readLine|>
 * .= Description
 * readLine attempts to read one line of text delimited by either LF
 * or CRLF and returns a <+NSString *+>. If an error occurs, <+nil+> is returned.
 * This call will block until a complete line can be read.
 **/
- (NSString *)	readLine;

/** .*** - readBytes
 * .= Declaration
 * <|- (NSData *) readBytes: (int)len|>
 * .= Description
 * readBytes attempts to read the specified number of bytes and returns a
 * <+NSData *+>.  If an error occurs, <+nil+> is returned. This call will block 
 * until the specified number of bytes becomes available.
 **/
- (NSData *)	readBytes: (int)len;

/** .*** - fillBuffer
 * .= Declaration
 * <|- (int) fillBuffer|>
 * .= Description
 * attempts to read some data from the socket and appends it to the buffer.
 * Returns the number of bytes actually read (zero in case of error).
 * This method is already invoked from readLine and readBytes, however
 * you can send this message to your sockets if you wish, e.g. if you want
 * to download a whole file into the buffer and then process it all at once.
 **/
- (NSInteger)		fillBuffer;

/** .*** - expect
 * .= Declaration
 * <|- (NSString *) expect: (NSString *)code or: (NSString *)exception|>
 * .= Description
 * expect will attempt to read one line from the socket and return it in a
 * <+NSString *+> if the beginning is equal to <+code+>. If an error occurs
 * or if the strings don't match, a <+NSException+> with the name
 * <+exception+> is raised.
 **/
- (NSString *) expect: (NSString *)code or: (NSString *)exception;

/** .*** - lastLine
 * .= Declaration
 * <|- (NSString *) lastLine|>
 * .= Description
 * returns the last line read by <+readLine+> or <+expect: or:+>. This is
 * the same <+NSString+> object which was returned by <+readLine+>. 
 **/
- (NSString *)	lastLine;

/** .*** - writeString
 * .= Declaration
 * <|- (NSString *) writeString: (NSString *)str|>
 * .= Description
 * writeString attempts to write a <+NSString *+> to the socket.
 * Expect that the <+cString+> representation be used. This call will block
 * until the string has actually been sent. It will return either its 
 * argument or <+nil+> if an error occurred.
 **/
- (NSString *)	writeString: (NSString *)str;

/** .*** - writeData
 * .= Declaration
 * <|- (NSData *) writeData: (NSData *)data|>
 * .= Description
 * writeData attempts to write the contents of a <+NSData *+> to the socket.
 * This call will block until the data has actually been sent. It will 
 * return either its argument or <+nil+> if an error occurred.
 **/
- (NSData *)	writeData: (NSData *)data;

/** .*** - printf
 * .= Declaration
 * <| - (NSString *) printf: (NSString *)format,... |>
 * .= Description
 * printf will take an arbitrary number of arguments and format them
 * according to a format string given as <+NSString *+>.
 * It will return a string representing what was actually written.
 * The format of the format string is the same as with the standard library
 * functions <+printf+>, <+fprintf+>, <+sprintf+>, <+snprintf+>, <+vsprintf+>,
 * and <+vsnprintf+>, and all the other funny-named functions I probably 
 * forgot.
 **/
- (NSString *)	printf: (NSString *)format, ... ;

/** .*** - setTimeout
 * .= Declaration
 * <|- (void) setTimeout: (int)nt|>
 * .= Description
 * Sets the timeout for read and write operations on this socket. Default
 * is no timeout.
 **/
- (void)	setTimeout: (int)nt;

/** .*** - canRead
 * .= Declaration
 * <|- (int) canRead|>
 * .= Description
 * Returns non-zero if there is data available, zero if not (or if the
 * operation timed out).
 **/
- (int)		canRead;

- (id)		init;
- (void)	dealloc;
@end
