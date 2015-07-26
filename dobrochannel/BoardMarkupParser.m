//
//  BoardMarkupParser.m
//  dobrochannel
//
//  Created by shdwprince on 7/23/15.
//  Copyright © 2015 Vasiliy Horbachenko. All rights reserved.
//

#import "BoardMarkupParser.h"

@implementation BoardMarkupParser

//@TODO: 100% bug fix

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
    NSDictionary<NSString *, id> *baseAttributes;
    // @todo base attributes

    int tagLength[] = {
        2, // bold
        4, // italic
        4, // spoiler
        4, // bold + italic
    };

    for (int i = 0; i < [str length]; i++) {
        unichar ch = [str.string characterAtIndex:i];

        if (ch == '_' || ch == '*' || ch == '%') {
            NSString *scanseq = [NSString stringWithCharacters:&ch length:1];
            NSScanner *scanner = [self scannerForString:[self faillesSubstringFrom:i + 1 of:str.string]];
            NSString *subexpression;
            NSInteger tag = BoardMarkupParserTagBold;

            // if there's another scanseq ahead its a two-char tag
            if (![scanner scanUpToString:scanseq intoString:&subexpression]) {
                scanner = [self scannerForString:[self faillesSubstringFrom:i + 2 of:str.string]];
                tag = ch == '%' ? BoardMarkupParserTagSpoiler : BoardMarkupParserTagItalic;
                [scanner scanUpToString:[scanseq stringByAppendingString:scanseq] intoString:&subexpression];
            }

            // subexpression found, parse it
            BOOL reachedEOL = scanner.scanLocation == [scanner.string length];
            BOOL substartingSpace = [subexpression characterAtIndex:0] == ' ';
            if (!reachedEOL && !substartingSpace && subexpression) {
                NSDictionary *attrs = self.attrs[[NSNumber numberWithInt:tag]];

                // if it's bold or italic tag, and there's already font attribute
                // addBoldItalic tag attributes
                if ([[[baseAttributes keyEnumerator] nextObject] isEqualToString:NSFontAttributeName]
                    && (tag == BoardMarkupParserTagBold || tag == BoardMarkupParserTagItalic)) {
                    attrs = self.attrs[[NSNumber numberWithInt:BoardMarkupParserTagBoldItalic]];
                    baseAttributes = nil;
                }

                NSMutableAttributedString *attributedText = [self parseAttributedString:[[NSMutableAttributedString alloc]
                                                                                         initWithString:subexpression
                                                                                         attributes:attrs]];

                // remove original subexpression
                [str deleteCharactersInRange:NSMakeRange(i, [subexpression length] + tagLength[tag])];
                // insert parsed one
                [str insertAttributedString:attributedText atIndex:i];
                // skip it at next iteration
                i += [attributedText length];
            }
        }
    }

    if (baseAttributes)
        [str addAttributes:baseAttributes range:NSMakeRange(0, [str length])];

    return str;
}

- (NSMutableAttributedString *) parse:(NSString *) str {
    return [self parseAttributedString:[[NSMutableAttributedString alloc] initWithString:str]];
}

@end
