//
//  PRShelf.m
//  PDFReader
//
//  Created by KO on 12/06/08.
//  Copyright (c) 2012年 KO. All rights reserved.
//

#import "PRShelf.h"
#import "PRDocument.h"

@implementation PRShelf

@synthesize uid = uid_;
@synthesize name = name_;
@synthesize documents = documents_;

- (NSUInteger)documentCount
{
    return documents_.count;
}

- (PRDocument*)documentAtIndex:(NSUInteger)index
{
    return [documents_ objectAtIndex:index];
}

#pragma mark - 初期化

- (id)initWithName:(NSString*)name;
{
    self = [super init];
    if (self) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        uid_ = (NSString*)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        name_ = [name copy];
        documents_ = [[NSMutableArray array] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [uid_ release], uid_ = nil;
    [name_ release], name_ = nil;
    [documents_ release], documents_ = nil;
    
    [super dealloc];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    if (self) {
        uid_ = [[decoder decodeObjectForKey:@"uid"] retain];
        name_ = [[decoder decodeObjectForKey:@"name"] retain];
        documents_ = [[decoder decodeObjectForKey:@"documents"] retain];
    }    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:uid_ forKey:@"uid"];
    [encoder encodeObject:name_ forKey:@"name"];
    [encoder encodeObject:documents_ forKey:@"documents"];
}

#pragma mark - documentの操作

- (void)addDocument:(PRDocument*)document
{
    if (!document) {
        return;
    }
    [documents_ addObject:document];
}

- (void)insertDocument:(PRDocument*)document atIndex:(NSUInteger)index
{
    if (!document) {
        return;
    }
    if (index > [documents_ count]) {
        return;
    }
    [documents_ insertObject:document atIndex:index];
}

- (void)removeDocument:(PRDocument*)document
{
    [documents_ removeObject:document];
}

- (void)removeDocumentAtIndex:(NSUInteger)index
{
    if (index > [documents_ count] - 1) {
        return;
    }
    [documents_ removeObjectAtIndex:index];
}

- (void)removeDocuments:(NSArray*)documents
{
    [documents_ removeObjectsInArray:documents];
}

- (void)moveDocumentAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (fromIndex > [documents_ count] - 1) {
        return;
    }
    if (toIndex > [documents_ count]) {
        return;
    }
    
    PRDocument* document = [documents_ objectAtIndex:fromIndex];
    [document retain];
    [documents_ removeObject:document];
    [documents_ insertObject:document atIndex:toIndex];
    [document release];
}

- (BOOL)containsDocument:(PRDocument*)doc
{
    return [documents_ containsObject:doc];
}

@end
