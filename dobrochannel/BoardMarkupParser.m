//
//  BoardMarkupParser.m
//  dobrochannel
//
//  Created by shdwprince on 7/23/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardMarkupParser.h"

@implementation BoardMarkupEntry
@synthesize type, expression;
- (instancetype) initWithType:(NSString *) _tp
                   expression:(NSString *) _expr {
    self = [super init];
    type = _tp;
    expression = _expr;
    return self;
}
@end

@interface BoardMarkupParser ()
@property CGFloat fontSize;
@end @implementation BoardMarkupParser

+ (instancetype) defaultParser {
    static BoardMarkupParser *parser = nil;
    UIFont *defaultFont = [UserDefaults messageFont];
    CGFloat size = defaultFont.pointSize;

    if (!parser) {
        UIColor *quoteColor = [UIColor colorWithRed:120.f/255.f green:153.f/255.f blue:34.f/255.f alpha:1.f];
        parser = [[BoardMarkupParser alloc] initWithAttributes:
                  @{
                     @BoardMarkupParserText: @{NSFontAttributeName: defaultFont},
                     @BoardMarkupParserTagBold: @{NSFontAttributeName:[UIFont boldSystemFontOfSize:size], },
                     @BoardMarkupParserTagItalic: @{NSFontAttributeName:[UIFont italicSystemFontOfSize:size], },
                     @BoardMarkupParserTagBoldItalic: @{NSFontAttributeName:[UIFont fontWithName:@"Georgia-BoldItalic" size:size], },
                     @BoardMarkupParserTagSpoiler: @{NSForegroundColorAttributeName: [UIColor grayColor],
                                                     NSBackgroundColorAttributeName: [UIColor blackColor],
                                                     NSFontAttributeName: defaultFont, },
                     @BoardMarkupParserWeblink: @{NSFontAttributeName: defaultFont,},
                     @BoardMarkupParserBoardlink: @{NSFontAttributeName: defaultFont,},
                     @BoardMarkupParserQuote: @{NSForegroundColorAttributeName: quoteColor,
                                                NSFontAttributeName: defaultFont,}, }];
        
        parser.fontSize = size;
    }
    
    return parser;
}

- (instancetype) initWithAttributes:(NSDictionary *)attrs {
    self = [super init];

    self.attrs = attrs;

    return self;
}

- (NSString *) faillesSubstringFrom:(NSUInteger) index of:(NSString *) str {
    if (index >= [str length])
        return @"";
    else
        return [str substringFromIndex:index];
}

- (NSScanner *) scannerForString:(NSString *) str {
    NSScanner *scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:nil];
    return scanner;
}

- (NSMutableAttributedString *) parseAttributedString:(NSMutableAttributedString *) str {
    NSDictionary *baseAttributes;
    if (str.length)
        baseAttributes = [str attributesAtIndex:0 effectiveRange:nil];

    NSCharacterSet *spacingSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r ,"];
    NSArray *linkProtocols = @[@"http://", @"https://", @"ftp://", ];

    int tagLength[] = {
        2, // bold
        4, // italic
        4, // spoiler
        4, // bold + italic
        0, // weblink
        0, // boardlink
        0, // quote
    };

    for (int i = 0; i < [str length]; i++) {
        unichar prech = 0;
        unichar ch = [str.string characterAtIndex:i];
        if (i > 0)
            prech = [str.string characterAtIndex:i-1];

        NSString *scanseq = [NSString stringWithCharacters:&ch length:1];
        NSScanner *scanner = [self scannerForString:[self faillesSubstringFrom:i of:str.string]];

        NSString *subexpression;
        NSInteger tag = -1;
        BOOL reachedEOL = NO;
        BOOL substartingSpace = NO;
        BOOL parseInsides = YES;

        // link
        if ([spacingSet characterIsMember:ch] || prech == 0 || prech == '\n') {
            NSString *protocol, *protocol_expr, *url;

            for (NSString *proto in linkProtocols) {
                [scanner scanString:[scanseq stringByAppendingString:proto] intoString:&protocol_expr];
                if (protocol_expr) {
                    protocol = proto;
                    break;
                }
            }

            if (protocol) {
                [scanner scanUpToCharactersFromSet:spacingSet intoString:&url];

                if (url) {
                    subexpression = [protocol stringByAppendingString:url];
                    i++;
                    tag = BoardMarkupParserWeblink;
                    parseInsides = NO;
                }
            }
        }

        // boardlink
        if (ch == '>') {
            NSString *second;
            [scanner scanString:[scanseq stringByAppendingString:scanseq] intoString:&second];

            if (second) {
                NSString *postid;
                [scanner scanUpToCharactersFromSet:spacingSet intoString:&postid];

                if (postid) {
                    subexpression = [@">>" stringByAppendingString:postid];

                    tag = BoardMarkupParserBoardlink;
                    parseInsides = NO;
                }
            }
        }

        // quote
        if (tag == -1 && ch == '>' && (prech == 0 || prech == '\n')) {
            NSString *quoting;
            [scanner scanString:@">" intoString:&quoting];
            if (quoting) {
                [scanner scanUpToString:@"\n" intoString:&subexpression];
                if (subexpression) {
                    subexpression = [@">" stringByAppendingString:subexpression];
                    tag = BoardMarkupParserQuote;
                    parseInsides = NO;
                }
                // @TODO: parse insides of quote
            }
        }

        // bold+italics
        if (ch == '_' || ch == '*' || ch == '%') {
            tag = BoardMarkupParserTagBold;
            scanner.scanLocation++;

            // if there's another scanseq ahead its a two-char tag
            if (![scanner scanUpToString:scanseq intoString:&subexpression]) {
                scanner = [self scannerForString:[self faillesSubstringFrom:i + 2 of:str.string]];
                tag = ch == '%' ? BoardMarkupParserTagSpoiler : BoardMarkupParserTagItalic;
                [scanner scanUpToString:[scanseq stringByAppendingString:scanseq] intoString:&subexpression];
            }

            // subexpression found, parse it
            reachedEOL = scanner.scanLocation == [scanner.string length];
            substartingSpace = [subexpression characterAtIndex:0] == ' ';
        }

        if (tag != -1 && !reachedEOL && !substartingSpace && subexpression) {
            NSDictionary *attrs = self.attrs[[NSNumber numberWithInt:tag]];
            NSMutableAttributedString *attributedText;

            if (parseInsides) {
                attributedText = [self parseAttributedString:[[NSMutableAttributedString alloc]
                                                                                         initWithString:subexpression
                                                                                         attributes:attrs]];
            } else {
                attributedText = [[NSMutableAttributedString alloc] initWithString:subexpression
                                                                        attributes:attrs];
            }
            
            //@TODO: refactor
            if (tag == BoardMarkupParserWeblink) {
                NSURL *url = [NSURL URLWithString:[subexpression stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                if (url) {
                    [attributedText addAttribute:NSLinkAttributeName
                                           value:url
                                           range:NSMakeRange(0, [subexpression length])];
                }
            } else if (tag == BoardMarkupParserBoardlink) {
                NSString *identifier = [[subexpression substringFromIndex:2] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSURL *url = [NSURL URLWithString:[@"dobrochannel://" stringByAppendingString:identifier]];
                if (url) {
                    [attributedText addAttribute:NSLinkAttributeName
                                           value:url
                                           range:NSMakeRange(0, [subexpression length])];
                }
            }

            // remove original subexpression
            [str deleteCharactersInRange:NSMakeRange(i, [subexpression length] + tagLength[tag])];
            // insert parsed one
            [str insertAttributedString:attributedText atIndex:i];
            // skip it at next iteration
            i += [attributedText length];
        }
    }

    /*
    if (baseAttributes)
        [str addAttributes:baseAttributes range:NSMakeRange(0, [str length])];
     */

    return str;
}

- (NSMutableAttributedString *) parse:(NSString *) str {
    return [self parseAttributedString:[[NSMutableAttributedString alloc] initWithString:str
                                                                              attributes:self.attrs[@BoardMarkupParserText]]];
}

@end