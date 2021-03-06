//
//  MwfTableViewController.m
//  MwfTableViewController
//
//  Created by Meiwin Fu on 23/4/12.
//  Copyright (c) 2012 –MwF. All rights reserved.
//

#import "MwfTableViewController.h"
#import <objc/runtime.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define kAnimationDuration 0.3
#define kLvBgColor     [UIColor colorWithRed:(226/255.f) green:(231/255.f) blue:(237/255.f) alpha:1]
#define kLvTextColor   [UIColor colorWithRed:(136/255.f) green:(146/255.f) blue:(165/255.f) alpha:1]
#define kLvShadowColor [UIColor whiteColor]

#define $ip(_section_,_row_) [NSIndexPath indexPathForRow:(_row_) inSection:(_section_)]

#define $inMain(_blok_) \
  dispatch_async(dispatch_get_main_queue(), (_blok_))

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface MwfTableData (PrivateMethods)
- (NSArray *) dataArray;
- (NSArray *) sectionArray;
@end

@interface MwfTableDataUpdates (PrivateMethods)
- (void) setReloadRows:(NSArray *)reloadRows;
- (void) setDeleteRows:(NSArray *)deleteRows;
- (void) setInsertRows:(NSArray *)insertRows;
- (void) setReloadSections:(NSIndexSet *)reloadSections;
- (void) setDeleteSections:(NSIndexSet *)deleteSections;
- (void) setInsertSections:(NSIndexSet *)insertSections;
@end

@interface MwfTableDataWithSections : MwfTableData
@end

@interface MwfTableDataProxy : MwfTableData {
  MwfTableData * _proxiedTableData;
  NSArray * _originalTableData;
  NSArray * _originalTableSection;
  
  NSMutableArray * _deletedSections;
  NSMutableArray * _insertedSections;
  NSMutableArray * _reloadedSections;
  NSMutableArray * _deletedRows;
  NSMutableArray * _insertedRows;
  NSMutableArray * _reloadedRows;

  NSMutableIndexSet * _deletedSectionIndexSets;
  NSMutableIndexSet * _insertedSectionIndexSets;
  NSMutableIndexSet * _reloadedSectionIndexSets;
  NSMutableArray * _deletedRowIndexPaths;
  NSMutableArray * _insertedRowIndexPaths;
  NSMutableArray * _reloadedRowIndexPaths;
}
@property (nonatomic,readonly) NSIndexSet * deletedSectionIndexSets;
@property (nonatomic,readonly) NSIndexSet * insertedSectionIndexSets;
@property (nonatomic,readonly) NSIndexSet * reloadedSectionIndexSets;
@property (nonatomic,readonly) NSArray * deletedRowIndexPaths;
@property (nonatomic,readonly) NSArray * insertedRowIndexPaths;
@property (nonatomic,readonly) NSArray * reloadedRowIndexPaths;
- (id) initWithTableData:(MwfTableData *)tableData;
- (void) beginUpdates;
- (void) endUpdates;
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation MwfTableDataUpdates
@synthesize reloadRows = _reloadRows;
@synthesize deleteRows = _deleteRows;
@synthesize insertRows = _insertRows;
@synthesize reloadSections = _reloadSections;
@synthesize deleteSections = _deleteSections;
@synthesize insertSections = _insertSections;
- (void)setReloadRows:(NSArray *)reloadRows;
{
  _reloadRows = reloadRows;
}
- (void)setDeleteRows:(NSArray *)deleteRows;
{
  _deleteRows = deleteRows;
}
- (void)setInsertRows:(NSArray *)insertRows;
{
  _insertRows = insertRows;
}
- (void)setInsertSections:(NSIndexSet *)insertSections;
{
  _insertSections = insertSections;
}
- (void)setDeleteSections:(NSIndexSet *)deleteSections;
{
  _deleteSections = deleteSections;
}
- (void)setReloadSections:(NSIndexSet *)reloadSections;
{
  _reloadSections = reloadSections;
}
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation MwfTableData
- (id)init {
  self = [super init];
  if (self) {
    _dataArray = [[NSMutableArray alloc] init];
  }
  return self;
}
// Creating instance
+ (MwfTableData *) createTableData;
{
  return [[MwfTableData alloc] init];
}
+ (MwfTableData *) createTableDataWithSections;
{
  return [[MwfTableDataWithSections alloc] init];
}
// Accessing data
- (NSUInteger) numberOfSections;
{
  return 1;
}
- (NSUInteger) numberOfRowsInSection:(NSUInteger)section;
{
  NSUInteger rowsCount = NSNotFound;
  if (section == 0) {
    rowsCount = _dataArray.count;
  }
  return rowsCount;
}
- (NSUInteger) numberOfRows;
{
  return [self numberOfRowsInSection:0];
}
- (id) objectForSectionAtIndex:(NSUInteger)section;
{
  return nil;
}
- (id)objectForRowAtIndexPath:(mwf_ip)ip;
{
  id object = nil;
  if (ip && ip.section == 0) {
    object = [_dataArray objectAtIndex:ip.row];
  } else if (ip.section != 0) {
    [NSException raise:@"UnsupportedOperation" format:@"Accessing object of non-0 section is not supported."];
  }
  return object;
}
- (mwf_ip) indexPathForRow:(id)object;
{
  NSUInteger idx = NSNotFound;
  if (object) {
    idx = [_dataArray indexOfObject:object];
  }
  mwf_ip ip = nil;
  if (idx != NSNotFound) ip = $ip(0,idx);
  return ip;
}
- (NSUInteger) indexForSection:(id)sectionObject;
{
  return NSNotFound;
}
- (BOOL) isEmpty;
{
  return [self numberOfRows] == 0;
}

// Inserting data
- (NSUInteger)addSection:(id)sectionObject;
{
  return [self insertSection:sectionObject atIndex:0];
}
- (NSUInteger)insertSection:(id)sectionObject atIndex:(NSUInteger)sectionIndex;
{
  [NSException raise:@"UnsupportedOperation" format:@"Adding section is not supported."];
  return NSNotFound;
}
- (mwf_ip)addRow:(id)object inSection:(NSUInteger)sectionIndex;
{
  mwf_ip ip = nil;
  if (object && sectionIndex == 0) {
    [_dataArray addObject:object];
    ip = $ip(0,[_dataArray count]-1);
  }
  return ip;
}
- (mwf_ip)insertRow:(id)object atIndexPath:(mwf_ip)indexPath;
{
  mwf_ip ip = nil;
  if (object && indexPath.section == 0) {
    [_dataArray insertObject:object atIndex:indexPath.row];
    ip = indexPath;
  } else if (indexPath.section != 0) {
    [NSException raise:@"UnsupportedOperation" format:@"Adding row in non-0 section is not supported."];
  }
  return ip;
}
- (mwf_ip)addRow:(id)object;
{
  return [self addRow:object inSection:0];
}
- (mwf_ip)insertRow:(id)object atIndex:(NSUInteger)index;
{
  return [self insertRow:object atIndexPath:$ip(0,index)];
}

// Deleting data
- (NSUInteger)removeSectionAtIndex:(NSUInteger)sectionIndex;
{
  [NSException raise:@"UnsupportedOperation" format:@"Removing section is not supported."];
  return NSNotFound;
}
- (mwf_ip)removeRowAtIndexPath:(mwf_ip)indexPath;
{
  mwf_ip ip = nil;
  if (indexPath && indexPath.section == 0) {
    [_dataArray removeObjectAtIndex:indexPath.row];
    ip = indexPath;
  } else if (indexPath.section != 0) {
    [NSException raise:@"UnsupportedOperation" format:@"Removing row in non-0 section is not supported."];
  }
  return ip;
}
// Update data
- (NSUInteger)updateSection:(id)object atIndex:(NSUInteger)section;
{
  return NSNotFound;
}
- (mwf_ip)updateRow:(id)object atIndexPath:(mwf_ip)indexPath;
{
  mwf_ip ip = nil;
  if (object && indexPath) {
    [_dataArray removeObjectAtIndex:indexPath.row];
    [_dataArray insertObject:object atIndex:indexPath.row];
    ip = indexPath;
  }
  return ip;
}

// Bulk Updates
- (MwfTableDataUpdates *)performUpdates:(void(^)(MwfTableData *))updates;
{
  MwfTableDataUpdates * u = nil;
  if (updates != NULL) {
    MwfTableDataProxy * proxy = [[MwfTableDataProxy alloc] initWithTableData:self];
    [proxy beginUpdates];
    updates(proxy);
    [proxy endUpdates];
    u = [[MwfTableDataUpdates alloc] init];
    u.reloadSections = proxy.reloadedSectionIndexSets;
    u.deleteSections = proxy.deletedSectionIndexSets;
    u.insertSections = proxy.insertedSectionIndexSets;
    u.reloadRows = proxy.reloadedRowIndexPaths;
    u.deleteRows = proxy.deletedRowIndexPaths;
    u.insertRows = proxy.insertedRowIndexPaths;
  }
  return u;
}
// Private Methods
- (NSArray *) dataArray;
{
  return _dataArray;
}
- (NSArray *) sectionArray;
{
  return _sectionArray;
}
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - MwfTableDataWithSections
@implementation MwfTableDataWithSections
// Private Mehos
- (NSMutableArray *) $section:(NSUInteger)section;
{
  return (NSMutableArray *) [_dataArray objectAtIndex:section];
}

// Init
- (id)init {
  self = [super init];
  if (self) {
    _sectionArray = [[NSMutableArray alloc] init];
  }
  return self;
}

// Accessing data
- (NSUInteger) numberOfSections;
{
  return [_dataArray count];
}
- (NSUInteger) numberOfRowsInSection:(NSUInteger)section;
{
  return [self $section:section].count;
}
- (NSUInteger) numberOfRows;
{
  return [self numberOfRowsInSection:0];
}
- (id) objectForSectionAtIndex:(NSUInteger)section;
{
  return [_sectionArray objectAtIndex:section];
}
- (id)objectForRowAtIndexPath:(mwf_ip)ip;
{
  id object = nil;
  if (ip) {
    object = [[self $section:ip.section] objectAtIndex:ip.row];
  }
  return object;
}
- (mwf_ip) indexPathForRow:(id)object;
{
  NSUInteger section = 0;
  NSUInteger idx = NSNotFound;
  if (object) {
    for (NSArray * arr in _dataArray) {
      idx = [arr indexOfObject:object];
      if (idx != NSNotFound) break;
      section++;
    }
  }
  mwf_ip ip = nil;
  if (idx != NSNotFound) ip = $ip(section,idx);
  return ip;
}
- (NSUInteger) indexForSection:(id)sectionObject;
{
  return [_sectionArray indexOfObject:sectionObject];
}
- (BOOL)isEmpty;
{
  for (NSArray * rows in _dataArray) {
    if ([rows count] > 0) return NO;
  }
  return YES;
}

// Inserting data
- (NSUInteger)addSection:(id)sectionObject;
{
  NSUInteger section = NSNotFound;
  if (sectionObject) {
    [_sectionArray addObject:sectionObject];
    section = [_sectionArray count]-1;
    [_dataArray addObject:[[NSMutableArray alloc] init]];
  }
  return section;
}
- (NSUInteger)insertSection:(id)sectionObject atIndex:(NSUInteger)sectionIndex;
{
  NSUInteger section = NSNotFound;
  if (sectionObject) {
    [_sectionArray insertObject:sectionObject atIndex:sectionIndex];
    [_dataArray insertObject:[[NSMutableArray alloc] init] atIndex:sectionIndex];
    section = sectionIndex;
  }
  return section;
}
- (mwf_ip)addRow:(id)object inSection:(NSUInteger)sectionIndex;
{
  mwf_ip ip = nil;
  if (object) {
    NSMutableArray * arr = [self $section:sectionIndex];
    [arr addObject:object];
    ip = $ip(sectionIndex, [arr count]-1);
  }
  return ip;
}
- (mwf_ip)insertRow:(id)object atIndexPath:(mwf_ip)indexPath;
{
  mwf_ip ip = nil;
  if (object && indexPath) {
    NSMutableArray * arr = [self $section:indexPath.section];
    [arr insertObject:object atIndex:indexPath.row];
    ip = indexPath;
  }
  return ip;
}
- (mwf_ip)addRow:(id)object;
{
  return [self addRow:object inSection:0];
}
- (mwf_ip)insertRow:(id)object atIndex:(NSUInteger)index;
{
  return [self insertRow:object atIndexPath:$ip(0,index)];
}

// Deleting data
- (NSUInteger)removeSectionAtIndex:(NSUInteger)sectionIndex;
{
  NSUInteger section = NSNotFound;
  [_sectionArray removeObjectAtIndex:sectionIndex];
  [_dataArray removeObjectAtIndex:sectionIndex];
  section = sectionIndex;
  return section;
}
- (mwf_ip)removeRowAtIndexPath:(mwf_ip)indexPath;
{
  mwf_ip ip = nil;
  if (indexPath) {
    NSMutableArray * arr = [self $section:indexPath.section];
    [arr removeObjectAtIndex:indexPath.row];
    ip = indexPath;
  }
  return ip;
}
// Update data
- (NSUInteger)updateSection:(id)object atIndex:(NSUInteger)section;
{
  NSUInteger s = NSNotFound;
  if (object) {
    [_sectionArray removeObjectAtIndex:section];
    [_sectionArray insertObject:object atIndex:section];
    s = section;
  }
  return s;
}
- (mwf_ip)updateRow:(id)object atIndexPath:(mwf_ip)indexPath;
{
  mwf_ip ip = nil;
  if (object && indexPath) {
    NSMutableArray * rows = [_dataArray objectAtIndex:indexPath.section];
    [rows removeObjectAtIndex:indexPath.row];
    [rows insertObject:object atIndex:indexPath.row];
    ip = indexPath;
  }
  return ip;
}

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation MwfTableDataProxy
@synthesize reloadedSectionIndexSets = _reloadedSectionIndexSets;
@synthesize deletedSectionIndexSets = _deletedSectionIndexSets;
@synthesize insertedSectionIndexSets = _insertedSectionIndexSets;
@synthesize reloadedRowIndexPaths = _reloadedRowIndexPaths;
@synthesize deletedRowIndexPaths = _deletedRowIndexPaths;
@synthesize insertedRowIndexPaths = _insertedRowIndexPaths;

- (id) initWithTableData:(MwfTableData *)tableData;
{
  self = [super init];
  if (self) {
    _proxiedTableData = tableData;
    _dataArray = nil;
    _sectionArray = nil;
  }
  return self;
}
// Updates
- (void)beginUpdates;
{
  _originalTableSection = [_proxiedTableData.sectionArray copy];
  if ([_proxiedTableData isKindOfClass:[MwfTableDataWithSections class]]) {
    NSMutableArray * originalTableData = [[NSMutableArray alloc] init];
    for (NSArray * rows in _proxiedTableData.dataArray) {
      [originalTableData addObject:[rows copy]];
    }
    _originalTableData = originalTableData;
  } else {
    _originalTableData = [_proxiedTableData.dataArray copy];
  }
  _deletedSections = [[NSMutableArray alloc] init];
  _insertedSections = [[NSMutableArray alloc] init];
  _reloadedSections = [[NSMutableArray alloc] init];
  _deletedRows = [[NSMutableArray alloc] init];
  _insertedRows = [[NSMutableArray alloc] init];
  _reloadedRows = [[NSMutableArray alloc] init];
}

- (NSUInteger) originalIndexForSection:(id)section;
{
  return [_originalTableSection indexOfObject:section];
}

- (mwf_ip) originalIndexPathForRow:(id)object;
{
  mwf_ip r = nil;
  NSUInteger section = 0;
  NSUInteger row = NSNotFound;
  if ([_proxiedTableData isKindOfClass:[MwfTableDataWithSections class]]) {
    for (NSArray * rows in _originalTableData) {
      row = [rows indexOfObject:object];
      if (row != NSNotFound) break;
      section++;
    }
  } else {
    row = [_originalTableData indexOfObject:object];
  }
  if (row != NSNotFound) {
    r = $ip(section,row);
  }
  return r;
}

- (void)endUpdates;
{
  if ([_reloadedSections count] > 0) _reloadedSectionIndexSets = [[NSMutableIndexSet alloc] init];
  if ([_deletedSections count] > 0) _deletedSectionIndexSets = [[NSMutableIndexSet alloc] init];
  if ([_insertedSections count] > 0) _insertedSectionIndexSets = [[NSMutableIndexSet alloc] init];
  if ([_reloadedRows count] > 0) _reloadedRowIndexPaths = [[NSMutableArray alloc] init];
  if ([_deletedRows count] > 0) _deletedRowIndexPaths = [[NSMutableArray alloc] init];
  if ([_insertedRows count] > 0) _insertedRowIndexPaths = [[NSMutableArray alloc] init];
  
  // reloaded rows
  for (id reloaded in _reloadedRows) {
    mwf_ip ip = [self originalIndexPathForRow:reloaded];
    if (ip && ![_reloadedRowIndexPaths containsObject:ip]) {
      [_reloadedRowIndexPaths addObject:ip];
    }
  }
  // reloaded sections
  for (id reloaded in _reloadedSections) {
    NSUInteger index = [self originalIndexForSection:reloaded];
    if (index != NSNotFound && ![_reloadedSectionIndexSets containsIndex:index]) {
      [_reloadedSectionIndexSets addIndex:index];
    }
  }
  
  // deleted rows
  for (id deleted in _deletedRows) {
    mwf_ip ip = [self originalIndexPathForRow:deleted];
    if (ip) {
      [_deletedRowIndexPaths addObject:ip];
    }
  }
  // deleted sections
  for (id deleted in _deletedSections) {
    NSUInteger index = [self originalIndexForSection:deleted];
    if (index != NSNotFound) {
      [_deletedSectionIndexSets addIndex:index];
    }
  }
  
  // inserted rows
  for (id inserted in _insertedRows) {
    mwf_ip ip = [self indexPathForRow:inserted];
    if (ip) {
      [_insertedRowIndexPaths addObject:ip];
    }
  }
  // inserted sections
  for (id inserted in _insertedSections) {
    NSUInteger index = [self indexForSection:inserted];
    if (index != NSNotFound) {
      [_insertedSectionIndexSets addIndex:index];
    }
  }
  
  // sorting the results
  NSComparisonResult(^Comparator)(mwf_ip ip1, mwf_ip ip2) = ^NSComparisonResult(mwf_ip ip1, mwf_ip ip2) {
    if (ip1.section == ip2.section) {
      return ip1.row > ip2.row ? NSOrderedDescending : NSOrderedAscending;
    }
    return ip1.section > ip2.section ? NSOrderedDescending : NSOrderedAscending;
  };
  
  [_reloadedSectionIndexSets removeIndexes:_deletedSectionIndexSets];
  [_reloadedRowIndexPaths removeObjectsInArray:_deletedRowIndexPaths];
  
  [_reloadedRowIndexPaths sortUsingComparator:Comparator];
  [_deletedRowIndexPaths sortUsingComparator:Comparator];
  [_insertedRowIndexPaths sortUsingComparator:Comparator];  

  _originalTableSection = nil;
  _originalTableData = nil;
  _deletedSections = nil;
  _insertedSections = nil;
  _reloadedSections = nil;
  _deletedRows = nil;
  _insertedRows = nil;
  _reloadedRows = nil;
 
}

// Accessing data
- (NSUInteger) numberOfSections;
{
  return _proxiedTableData.numberOfSections;
}
- (NSUInteger) numberOfRowsInSection:(NSUInteger)section;
{
  return [_proxiedTableData numberOfRowsInSection:section];
}
- (NSUInteger) numberOfRows;
{
  return _proxiedTableData.numberOfRows;
}
- (id) objectForRowAtIndexPath:(mwf_ip)ip;
{
  return [_proxiedTableData objectForRowAtIndexPath:ip];
}
- (mwf_ip) indexPathForRow:(id)object;
{
  return [_proxiedTableData indexPathForRow:object];
}
- (NSUInteger) indexForSection:(id)sectionObject;
{
  return [_proxiedTableData indexForSection:sectionObject];  
}

// Inserting data
- (NSUInteger)addSection:(id)sectionObject;
{
  NSUInteger r = [_proxiedTableData addSection:sectionObject];
  [_insertedSections addObject:sectionObject];
  return r;
}
- (NSUInteger)insertSection:(id)sectionObject atIndex:(NSUInteger)sectionIndex;
{
  NSUInteger r = [_proxiedTableData insertSection:sectionObject atIndex:sectionIndex];
  [_insertedSections addObject:sectionObject];
  return r;
}
- (mwf_ip)addRow:(id)object inSection:(NSUInteger)sectionIndex;
{
  mwf_ip r = [_proxiedTableData addRow:object inSection:sectionIndex];
  [_insertedRows addObject:object];
  return r;
}
- (mwf_ip)insertRow:(id)object atIndexPath:(mwf_ip)indexPath;
{
  mwf_ip r = [_proxiedTableData insertRow:object atIndexPath:indexPath];
  [_insertedRows addObject:object];
  return r;
}
- (mwf_ip)addRow:(id)object;
{
  mwf_ip r = [_proxiedTableData addRow:object];
  [_insertedRows addObject:object];
  return r;
}
- (mwf_ip)insertRow:(id)object atIndex:(NSUInteger)index;
{
  mwf_ip r = [_proxiedTableData insertRow:object atIndex:index];
  [_insertedRows addObject:object];
  return r;
}

// Deleting data
- (mwf_ip)removeRowAtIndexPath:(mwf_ip)indexPath;
{
  [_deletedRows addObject:[_proxiedTableData objectForRowAtIndexPath:indexPath]];
  mwf_ip r = [_proxiedTableData removeRowAtIndexPath:indexPath];
  return r;
}
- (NSUInteger)removeSectionAtIndex:(NSUInteger)sectionIndex;
{
  id deleted = [_proxiedTableData objectForSectionAtIndex:sectionIndex];
  [_deletedSections addObject:deleted];
  NSUInteger r = [_proxiedTableData removeSectionAtIndex:sectionIndex];
  return r;
}

// Update data
- (NSUInteger)updateSection:(id)object atIndex:(NSUInteger)section;
{
  id obj = [_proxiedTableData objectForSectionAtIndex:section];
  NSUInteger s = [_proxiedTableData updateSection:object atIndex:section];
  if (obj && s != NSNotFound) [_reloadedSections addObject:obj];
  return section;
}
- (mwf_ip)updateRow:(id)object atIndexPath:(mwf_ip)indexPath;
{
  id obj = [_proxiedTableData objectForRowAtIndexPath:indexPath];
  mwf_ip ip = [_proxiedTableData updateRow:object atIndexPath:indexPath];
  if (obj && ip) [_reloadedRows addObject:obj];
  return ip;
}

// Bulk Updates
- (MwfTableDataUpdates *)performUpdates:(void(^)(MwfTableData *))updates;
{
  [NSException raise:@"UnsupportedOperation" format:@"Unsupported operation"];
  return nil;
}
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - MwfDefaultTableLoadingView
@implementation MwfDefaultTableLoadingView
@synthesize textLabel = _textLabel;
@synthesize activityIndicatorView = _activityIndicatorView;
- (id)initWithFrame:(CGRect)frame;
{
  self = [super initWithFrame:frame];
  if (self) {
    
    self.backgroundColor = [UIColor clearColor];
    
    UILabel * l = [[UILabel alloc] initWithFrame:CGRectZero];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = kLvTextColor;
    l.shadowColor = kLvShadowColor;
    l.font = [UIFont boldSystemFontOfSize:18];
    [self addSubview:l];
    _textLabel = l;
    _textLabel.text = NSLocalizedString(@"Loading...", @"Loading...");

    UIActivityIndicatorView * aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    aiv.backgroundColor = [UIColor clearColor];
    [self addSubview:aiv];
    _activityIndicatorView = aiv;
    [_activityIndicatorView startAnimating];
    
    [self setNeedsLayout];
    
  }
  return self;
}
- (void)layoutSubviews;
{
  [super layoutSubviews];
  
  CGSize selfSize = self.bounds.size;
  
  [_textLabel sizeToFit];
  CGFloat labelW = _textLabel.bounds.size.width;
  if (labelW > selfSize.width-40) labelW = selfSize.width-40;
  CGFloat labelH = _textLabel.bounds.size.height;
  _textLabel.frame = CGRectMake(floor(((selfSize.width-labelW)/2)), floor((selfSize.height-labelH)/2), labelW, labelH);
  
  [_activityIndicatorView sizeToFit];
  CGSize aivSize = _activityIndicatorView.bounds.size;
  CGFloat aivH = aivSize.height;
  CGFloat aivW = aivSize.width;
  _activityIndicatorView.frame = CGRectMake(_textLabel.frame.origin.x-30, floor(_textLabel.frame.origin.y+(labelH-aivH)/2), aivW, aivH);
}
+ (MwfDefaultTableLoadingView *)create;
{
  return [[MwfDefaultTableLoadingView alloc] initWithFrame:CGRectMake(0, -60, 320, 60)];
}
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - MwfTableViewController
@interface MwfTableViewController ()
- (void)initialize;
- (void)performUpdates:(void (^)(MwfTableData *))updates withTableData:(MwfTableData *)tableData tableView:(UITableView *)tableView;
@end

#define $impTarget       _implementationTarget
#define $impTargetClass  _implementationTargetClass
#define $createImpCache  _createImplementationCache
#define $createSelCache  _createSelectorCache
#define $configImpCache  _configImplementationCache
#define $configSelCache  _configSelectorCache

@implementation MwfTableViewController
@synthesize tableHeaderTopView     = _tableHeaderTopView;
@synthesize loading                = _loading;
@synthesize loadingView            = _loadingView;
@synthesize loadingStyle           = _loadingStyle;
@synthesize tableData              = _tableData;
@synthesize searchResultsTableData = _searchResultsTableData;
@synthesize wantSearch             = _wantSearch;
@synthesize searchDelayInSeconds   = _searchDelayInSeconds;

#pragma mark - Private
- (void)initialize;
{
  _tableData = [self createAndInitTableData];
  
  // IMP
  $impTarget = self;
  $impTargetClass = [$impTarget class];
  $createImpCache = [[NSMutableDictionary alloc] initWithCapacity:0];
  $configImpCache = [[NSMutableDictionary alloc] initWithCapacity:0]; 
  $createSelCache = [[NSMutableDictionary alloc] initWithCapacity:0];
  $configSelCache = [[NSMutableDictionary alloc] initWithCapacity:0];
  
  // search
  _searchDelayInSeconds = 0.5;
}
- (MwfTableData *)tableDataForTableView:(UITableView *)tableView;
{
  if (tableView == self.tableView) return _tableData;
  return _searchResultsTableData;
}
- (void)performUpdates:(void (^)(MwfTableData *))updates withTableData:(MwfTableData *)tableData tableView:(UITableView *)tableView;
{
  
  if (tableData) {
    
    __block MwfTableViewController * weakSelf = self;
    if (_isUpdating) {
      double delayInSeconds = 0.1;
      dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
      dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf setTableData:tableData];
      });
    } else {
      [self setTableDataInternal:tableData];
    }
  }
  
  if (updates != NULL) {
    
    __block MwfTableViewController * weakSelf = self;
    if (_isUpdating) {
      double delayInSeconds = 0.1;
      dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
      dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf performUpdates:updates withTableData:tableData tableView:tableView];
      });
    } else {
      _isUpdating = YES;
      void(^updateIt)(void) = ^{
        MwfTableDataUpdates * u = [tableData performUpdates:updates];
        if (u) {
          void(^go)(void) = ^{
            UITableViewRowAnimation rowAnimation = UITableViewRowAnimationAutomatic;
            [tableView beginUpdates];
            if (u.insertSections.count > 0) { 
              [tableView insertSections:u.insertSections withRowAnimation:rowAnimation]; 
            }
            if (u.deleteSections.count > 0) {
              [tableView deleteSections:u.deleteSections withRowAnimation:rowAnimation];
            }
            if (u.reloadSections.count > 0) {
              [tableView reloadSections:u.reloadSections withRowAnimation:rowAnimation];
            }
            if (u.deleteRows.count > 0) {
              [tableView deleteRowsAtIndexPaths:u.deleteRows withRowAnimation:rowAnimation];
            }
            if (u.reloadRows.count > 0) {
              [tableView reloadRowsAtIndexPaths:u.reloadRows withRowAnimation:rowAnimation];
            }
            if (u.insertRows.count > 0) {
              [tableView insertRowsAtIndexPaths:u.insertRows withRowAnimation:rowAnimation];
            }
            [tableView endUpdates];
            _isUpdating = NO;
          };
          if ([NSThread isMainThread]) {
            go();
          } else {
            $inMain(go);
          }
        } else {
          _isUpdating = NO;
        }
      };
      dispatch_async(dispatch_get_current_queue(), updateIt);
    }
  } 
}

#pragma mark - Init
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [self initialize];
  }
  return self;
}
- (id)initWithStyle:(UITableViewStyle)style;
{
  self = [super initWithStyle:style];
  if (self) {
    [self initialize];
  }
  return self;
}
- (void)awakeFromNib;
{
  [super awakeFromNib];
  [self initialize];
}
#pragma mark - View Lifecycle
- (void)loadView;
{
  [super loadView];
  
  CGRect b = self.view.bounds;

  if (self.tableView.style == UITableViewStylePlain) {
    
    // table header top view
    _tableHeaderTopView = [self createTableHeaderTopView];
    _tableHeaderTopView.frame = CGRectMake(0, -_tableHeaderTopView.bounds.size.height,
                                           b.size.width, _tableHeaderTopView.bounds.size.height);
    _tableHeaderTopView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.tableView addSubview:_tableHeaderTopView];
    
    // table footer bottom view
    _emptyTableFooterBottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, b.size.width, 0)];
    _emptyTableFooterBottomView.backgroundColor = [UIColor clearColor];
    
  }
  
  _loadingView = [self createLoadingView];
  _loadingView.hidden = YES;
  
  [self setWantSearch:_wantSearch];
}

- (void)viewDidUnload;
{
  [super viewDidUnload];
  
  _tableHeaderTopView = nil;
  _emptyTableFooterBottomView = nil;
  _loadingView = nil;
  __searchDisplayController = nil;
}

#pragma mark - Loading
- (void)setLoading:(BOOL)loading;
{
  [self setLoading:loading animated:NO];
}
- (void)setLoadingStyle:(MwfTableViewLoadingStyle)loadingStyle;
{
  _loadingStyle = loadingStyle;
  if (_loadingStyle != MwfTableViewLoadingStyleFooter) {
    self.tableView.tableFooterView = nil;
  } else if (_loadingStyle == MwfTableViewLoadingStyleFooter) {
    self.tableView.tableFooterView = _emptyTableFooterBottomView;
  }
}
- (void)setLoading:(BOOL)loading animated:(BOOL)animated;
{
  if (_loading != loading) {
    _loading = loading;
    
    void(^beforeBlock)(void);
    void(^animBlock)(void);
    void(^afterBlock)(BOOL finished);

    __block MwfTableViewController * weakSelf = self;
    if (_loadingStyle == MwfTableViewLoadingStyleHeader) {
      if (_loading) {
        beforeBlock = ^{ 
          _loadingView.frame = CGRectMake(0,-_loadingView.bounds.size.height,_loadingView.bounds.size.width,_loadingView.bounds.size.height);
          [weakSelf.view addSubview:_loadingView];
          [weakSelf willShowLoadingView:_loadingView];
          _loadingView.hidden = NO;
          weakSelf.tableView.contentInset = UIEdgeInsetsMake(_loadingView.bounds.size.height, 0, 0, 0);
        };
        animBlock = ^{ 
          weakSelf.tableView.contentOffset = CGPointMake(0, -_loadingView.bounds.size.height); 
        };
        afterBlock = NULL;
      } else {
        beforeBlock = NULL;
        animBlock = ^{ 
          weakSelf.tableView.contentInset = UIEdgeInsetsZero;      
          weakSelf.tableView.contentOffset = CGPointZero;
        };
        afterBlock = ^(BOOL finished) { 
          if (finished) {
            _loadingView.hidden = YES;
            [_loadingView removeFromSuperview];
            [weakSelf didHideLoadingView:_loadingView];
          }
        };
      }
    } else if (_loadingStyle == MwfTableViewLoadingStyleFooter) {
      if (_loading) {
        beforeBlock = ^{
          weakSelf.tableView.tableFooterView = _loadingView;
          [weakSelf willShowLoadingView:_loadingView];
          _loadingView.hidden = NO;
          CGFloat contentH = weakSelf.tableView.contentSize.height;
          [weakSelf.tableView scrollRectToVisible:CGRectMake(0, contentH-_loadingView.bounds.size.height,
                                                             weakSelf.tableView.bounds.size.width, _loadingView.bounds.size.height) 
                                         animated:YES];
        };
      } else {
        afterBlock = ^(BOOL finished) {
          if (finished) {
            _loadingView.hidden = YES;
            [weakSelf didHideLoadingView:_loadingView];
            weakSelf.tableView.tableFooterView = _emptyTableFooterBottomView;
          }
        };
      }
    }

    if (beforeBlock != NULL) beforeBlock();
    if (animated && animBlock != NULL) {
      [UIView animateWithDuration:kAnimationDuration animations:animBlock completion:afterBlock];
    } else {
      if (animBlock != NULL) {
        animBlock();
      }
      if (afterBlock != NULL) {
        afterBlock(YES);
      }
    }
  }
}

#pragma mark - OverrideForCustomView
- (UIView *) createTableHeaderTopView;
{
  CGRect b = self.view.bounds;
  UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, b.size.width, 1000)];
  view.backgroundColor = kLvBgColor;
  return view;
}

- (UIView *) createLoadingView;
{
  return [MwfDefaultTableLoadingView create];
}
- (void)willShowLoadingView:(UIView *)loadingView;
{
  if ([loadingView isKindOfClass:[MwfDefaultTableLoadingView class]]) {
    MwfDefaultTableLoadingView * defaultLoadingView = (MwfDefaultTableLoadingView *)loadingView;
    [defaultLoadingView.activityIndicatorView startAnimating];
  }
}
- (void)didHideLoadingView:(UIView *)loadingView;
{
  if ([loadingView isKindOfClass:[MwfDefaultTableLoadingView class]]) {
    MwfDefaultTableLoadingView * defaultLoadingView = (MwfDefaultTableLoadingView *)loadingView;
    [defaultLoadingView.activityIndicatorView stopAnimating];
  }
}

#pragma mark - Table Data
- (MwfTableData *)createAndInitTableData;
{
  return [MwfTableData createTableData];
}
- (void)setTableData:(MwfTableData *)tableData;
{
  if (tableData) {
    
    __block MwfTableViewController * weakSelf = self;
    if (_isUpdating) {
      double delayInSeconds = 0.1;
      dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
      dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf setTableData:tableData];
      });
    } else {
      [self setTableDataInternal:tableData];
    }
  }
}
- (void)setTableDataInternal:(MwfTableData *)tableData;
{
  _isUpdating = YES;
  _tableData = tableData;
  __block MwfTableViewController * weakSelf = self;
  void(^go)(void) = ^{
    [weakSelf.tableView reloadData];
    _isUpdating = NO;
  };
  if ([NSThread isMainThread]) {
    go();
  } else {
    $inMain(go);
  }
}
- (void)performUpdates:(void(^)(MwfTableData *))updates;
{
  [self performUpdates:updates 
         withTableData:self.tableData 
             tableView:self.tableView];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
  return [self tableDataForTableView:tableView].numberOfSections;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
  return [[self tableDataForTableView:tableView] numberOfRowsInSection:section];
}

#pragma mark - UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
  MwfTableData * targetTableData = (tableView == self.tableView ? self.tableData : self.searchResultsTableData); 
  id rowItem = [targetTableData objectForRowAtIndexPath:indexPath];

  UITableViewCell * cell = [self tableView:tableView cellForObject:rowItem atIndexPath:indexPath];
  
  // to prevent app crashing when returning nil
  if (!cell) {
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NilCell"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NilCell"];
  }
  
  return cell;
}

#pragma mark - TableViewCell
- (UITableViewCell *) tableView:(UITableView *)tableView 
                  cellForObject:(id)rowItem
                    atIndexPath:(NSIndexPath *)ip; 
{
  UITableViewCell * cell = nil;
  Class cellClass = nil;
  if (rowItem) {
    
    Class rowItemClass = object_getClass(rowItem);
    
    UITableView * tableView = self.tableView;
    
    SEL cellClassSEL = @selector(cellClass);
    IMP cellClassIMP = NULL;
    SEL reuseIdentifierSEL = @selector(reuseIdentifier);
    IMP reuseIdentifierIMP = NULL;
    
    if (class_respondsToSelector(rowItemClass, reuseIdentifierSEL)) {
      reuseIdentifierIMP = class_getMethodImplementation(rowItemClass, reuseIdentifierSEL);
    }
    
    if (reuseIdentifierIMP) { // the class implement reuseIdentifier method
      
      NSString * reuseIdentifier = (*reuseIdentifierIMP)(rowItem, reuseIdentifierSEL);
      
      if (reuseIdentifier) {
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        if (!cell) {
          
          if (class_respondsToSelector(rowItemClass, cellClassSEL)) {
            cellClassIMP = class_getMethodImplementation(rowItemClass, cellClassSEL);
          }
          if (cellClassIMP) {
            cellClass = (*cellClassIMP)(rowItem, @selector(cellClass));
            if (cellClass) {
              cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
              
              SEL setItemSEL = @selector(setItem:);
              if (class_respondsToSelector(cellClass, setItemSEL)) {
                IMP setItemIMP = class_getMethodImplementation(cellClass, setItemSEL);
                (*setItemIMP)(cell, setItemSEL, rowItem);
              }
            }
          }
        } else cellClass = [cell class];
      }
    }
    
    // determine target
    id target = rowItem;
    Class targetClass = rowItemClass;
    BOOL usingMwfTableItem = NO;
    id userInfo = nil;
    
    
    if (cell) {
      usingMwfTableItem = YES;
      SEL userInfoSEL = @selector(userInfo);
      IMP userInfoIMP = NULL;
      if (class_respondsToSelector(rowItemClass, userInfoSEL)) 
        userInfoIMP = class_getMethodImplementation(rowItemClass, userInfoSEL);
      
      if (userInfoIMP) {
        id tmpUserInfo = (*userInfoIMP)(rowItem, userInfoSEL);
        if (tmpUserInfo) {
          
          userInfo = tmpUserInfo;

          target = userInfo;
        }
      }
    }

    if (!cell) {
      
      // find IMP to call
      // e.g. item class = TestItem
      //      selector   = tableView:createCellForTestItem:"
      IMP createIMP = NULL; 
      SEL createSEL = NULL;
      id cached = (NSData *)[$createImpCache objectForKey:targetClass];
      if (cached != [NSNull null]) {
        
        if (cached) createIMP = *((IMP *)[cached bytes]);
        
        if (!createIMP) {
          BOOL keepChecking = YES;
          BOOL methodImplemented = NO;
          Class checkingClass = targetClass;
          while (keepChecking) {
            const char * selectorName = [[NSString stringWithFormat:@"tableView:cellFor%@AtIndexPath:", NSStringFromClass(checkingClass)] UTF8String];
            createSEL = sel_getUid(selectorName);
            if (!class_respondsToSelector($impTargetClass, createSEL)) {
              if (checkingClass == [NSObject class]) keepChecking = NO;
              else checkingClass = class_getSuperclass(checkingClass);
              if (checkingClass == nil) keepChecking = NO;
            } else {
              methodImplemented = YES;
              keepChecking = NO;
            }
          }
          if (methodImplemented) {
            createIMP = class_getMethodImplementation($impTargetClass, createSEL);
            if (createIMP) {
              [$createImpCache setObject:[NSData dataWithBytes:&createIMP length:sizeof(IMP)] 
                                  forKey:targetClass];
            }
          } else {
            [$createImpCache setObject:[NSNull null] forKey:targetClass];
          }
          [$createSelCache setObject:[NSData dataWithBytes:createSEL length:sizeof(SEL)] 
                              forKey:targetClass];
        } else {
          createSEL = *((SEL *)[(NSData *)[$createSelCache objectForKey:targetClass] bytes]);
        }
        
        // call the creation method
        if (createIMP) {
          cell = (UITableViewCell *) (*createIMP)($impTarget, createSEL, self.tableView, ip);
        }
      }
    }    
    
    if (cell && (userInfo || !usingMwfTableItem)) {
      
      // find IMP to call
      // e.g. item class = TestItem
      //      selector   = configCell:forTestItem:
      IMP configIMP = NULL;
      SEL configSEL = NULL;
      
      id cached = (NSData *)[$configImpCache objectForKey:targetClass];
      if (cached != [NSNull null]) {
        
        if (cached) configIMP = *((IMP *)[cached bytes]);
        
        if (!configIMP) {

          BOOL keepChecking = YES;
          BOOL methodImplemented = NO;
          Class checkingClass = targetClass;
          while (keepChecking) {
            const char * selectorName = nil; 
            if (!usingMwfTableItem) {
              selectorName = [[@"tableView:configCell:for" stringByAppendingFormat:@"%@:",NSStringFromClass(checkingClass)] UTF8String];
            } else {
              selectorName = [[@"tableView:configCell:for" stringByAppendingFormat:@"%@UserInfo:",NSStringFromClass(checkingClass)] UTF8String];
            }
            configSEL = sel_getUid(selectorName);
            
            if (!class_respondsToSelector($impTargetClass, configSEL)) {
              if (checkingClass == [NSObject class]) keepChecking = NO;
              else checkingClass = class_getSuperclass(checkingClass);
              if (checkingClass == nil) keepChecking = NO;
            } else {
              methodImplemented = YES;
              keepChecking = NO;
            }
          }
          
          if (methodImplemented)
            configIMP = class_getMethodImplementation($impTargetClass, configSEL);
          
          if (configIMP) {
            [$configImpCache setObject:[NSData dataWithBytes:&configIMP length:sizeof(IMP)] 
                                forKey:targetClass];
          } else {
            [$configImpCache setObject:[NSNull null] forKey:targetClass];
          }
          [$configSelCache setObject:[NSData dataWithBytes:&configSEL length:sizeof(SEL)] 
                              forKey:targetClass];
        } else {
          configSEL = *((SEL *)[(NSData *)[$configSelCache objectForKey:targetClass] bytes]);
        }
        
        // call the configure method
        if (configIMP) {
          (*configIMP)($impTarget, configSEL, self.tableView, cell, target);
        }
      }
    }      
    
  }
  return cell;
}

#pragma mark - Search
- (void)setSearchResultsTableData:(MwfTableData *)searchResultsTableData;
{
  if (searchResultsTableData) {
    _searchResultsTableData = searchResultsTableData;
    if (self.searchDisplayController.isActive) {
      __block MwfTableViewController * weakSelf = self;
      void(^go)(void) = ^{
        [weakSelf.searchDisplayController.searchResultsTableView reloadData];
      };
      if ([NSThread isMainThread]) {
        go();
      } else {
        $inMain(go);
      }
    }
  }
}
- (MwfTableData *)createAndInitSearchResultsTableData;
{
  return [MwfTableData createTableData];
}
- (void)setWantSearch:(BOOL)wantSearch;
{
  _wantSearch = wantSearch;
  
  if (![self isViewLoaded]) return;
  
  UISearchBar * searchBar = (UISearchBar *)([self.tableView.tableHeaderView isKindOfClass:[UISearchBar class]] ? self.tableView.tableHeaderView : nil);

  if (_wantSearch) {

    // add search bar and setup uisearchdisplaycontroller
    if (!searchBar) {
      searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
      searchBar.delegate = self;
      [searchBar sizeToFit];
    }

    if (!_searchResultsTableData) {
      self.searchResultsTableData = [self createAndInitSearchResultsTableData];
    }
    
    if (!__searchDisplayController) {
      
      __searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
      __searchDisplayController.delegate = self;
      __searchDisplayController.searchResultsDelegate = self;
      __searchDisplayController.searchResultsDataSource = self;
    }
    self.tableView.tableHeaderView = searchBar;
  } else {
    if (searchBar) {
      // remove search bar 
      [searchBar removeFromSuperview];
    }
    if (_searchResultsTableData) {
      _searchResultsTableData = nil;
    }
    if (__searchDisplayController) {
      // nullify uisearchdisplaycontroller
      __searchDisplayController = nil;
    }
    if (_searchResultsTableData) {
      // nullify table data
      _searchResultsTableData = nil;
    }
  }
}
- (MwfTableData *) createSearchResultsTableDataForSearchText:(NSString *)searchText scope:(NSString *)scope;
{
  return nil;
}
#pragma mark - Search Results
- (void)invokeSearchWithSearchCriteria:(NSDictionary *)criteria;
{
  NSString * searchText = [criteria objectForKey:@"searchText"];
  NSString * scope = [criteria objectForKey:@"scope"];
  MwfTableData * searchResultsTableData = [self createSearchResultsTableDataForSearchText:searchText scope:scope];
  self.searchResultsTableData = searchResultsTableData;
}
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString;
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(invokeSearchWithSearchCriteria:) object:_previousSearchCriteria];

  _previousSearchCriteria = [[NSMutableDictionary alloc] initWithCapacity:0];
  NSString * searchText = searchString;
  NSString * scope = [controller.searchBar.scopeButtonTitles objectAtIndex:controller.searchBar.selectedScopeButtonIndex];
  if (searchText) [_previousSearchCriteria setObject:searchText forKey:@"searchText"];
  if (scope)      [_previousSearchCriteria setObject:scope forKey:@"scope"];
  [self performSelector:@selector(invokeSearchWithSearchCriteria:) withObject:_previousSearchCriteria afterDelay:_searchDelayInSeconds];
  return NO;
}
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption;
{
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(invokeSearchWithSearchCriteria:) object:_previousSearchCriteria];
  
  _previousSearchCriteria = [[NSMutableDictionary alloc] initWithCapacity:0];
  NSString * searchText = controller.searchBar.text;
  NSString * scope = [controller.searchBar.scopeButtonTitles objectAtIndex:searchOption];
  if (searchText) [_previousSearchCriteria setObject:searchText forKey:@"searchText"];
  if (scope)      [_previousSearchCriteria setObject:scope forKey:@"scope"];
  [self performSelector:@selector(invokeSearchWithSearchCriteria:) withObject:_previousSearchCriteria afterDelay:_searchDelayInSeconds];
  return NO;
}
- (void)performUpdatesForSearchResults:(void(^)(MwfTableData *))updates;
{
  [self performUpdates:updates 
         withTableData:self.searchResultsTableData 
             tableView:self.searchDisplayController.searchResultsTableView];
}
@end
