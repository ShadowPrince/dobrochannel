//
//  BoardMarkupParser.h
//  dobrochannel
//
//  Created by shdwprince on 7/23/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#define BoardMarkupParserTagBold 0
#define BoardMarkupParserTagItalic 1
#define BoardMarkupParserTagSpoiler 2
#define BoardMarkupParserTagBoldItalic 3
#define BoardMarkupParserWeblink 4
#define BoardMarkupParserBoardlink 5
#define BoardMarkupParserQuote 6

@interface BoardMarkupEntry : NSObject
@property (readonly) NSString *type;
@property (readonly) NSString *expression;
- (instancetype) initWithType:(NSString *) _tp
                   expression:(NSString *) _expr;
@end

@interface BoardMarkupParser : NSObject
@property NSDictionary *attrs;

- (instancetype) initWithAttributes:(NSDictionary *) attrs;
- (NSMutableAttributedString *) parse:(NSString *) str;
@end
