//
//  AASDataGridView.m
//
//  Created by Alan Samet on 7/28/13.
//  Copyright (c) 2013 Panalucent LLC. All rights reserved.
//

#import "ASDataGridView.h"

@interface ASDataGridView () <UIScrollViewDelegate>
//@property (strong, nonatomic) IBOutlet UIScrollView *headerScrollView;
@property (strong, nonatomic) NSMutableArray *headerCells;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *gridSubview;
@property (strong, nonatomic) NSMutableArray *visibleRows;
@property (strong, nonatomic) NSMutableArray *availableRows;
@property (strong, nonatomic) NSMutableArray *selectedRowNumbersInternal;
//@property (strong, nonatomic) NSArray *columnDefinitions;
@end

@interface ASDataGridRowCell ()
@property (strong, nonatomic) id value;
@property (weak, nonatomic) NSArray *rowData;
@property (assign, nonatomic) int rowNumber;
- (void) render;
@end

@implementation ASSimpleDataGridViewDataSource
- (NSArray *)rows
{
    return [self.sourceData valueForKey:@"data"];
}

- (int)rowCount
{
    return [self.rows count];
}

- (NSArray *)rowDataForRowNumber:(int)rowNumber
{
    if (self.rowCount == 0)
        return nil;
    return [self.rows objectAtIndex:rowNumber];
}

- (NSArray *)columnNames
{
    return [self.sourceData valueForKey:@"columns"];
}
@end

@implementation ASFetchedResultsDataGridViewDataSource

- (int)rowCount
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    return [sectionInfo numberOfObjects];
}

- (NSArray *)rowDataForRowNumber:(int)rowNumber
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowNumber inSection:0];
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSMutableArray *values = [[NSMutableArray alloc]initWithCapacity:[self.columnNames count]];
    [self.columnNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id val = [object valueForKey:obj];
        if (val == nil)
            val = [NSNull null];
        [values setObject:val atIndexedSubscript:idx];
    }];
    return values;
}

- (NSArray *)columnNames
{
    if (self.rowCount == 0)
        return nil;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSArray *props = [[[object entity]attributesByName] allKeys];
    return props;
}

@end

@implementation ASDataGridColumnDefinition
- (id)init
{
    self = [super init];
    self.cellPadding = 4.0f;
    return self;
}
@end

@implementation ASDataGridRow

- (void)render
{
    [self.cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj render];
    }];
}

- (NSMutableArray *)cells
{
    if (_cells == nil)
        _cells = [[NSMutableArray alloc]init];
    return _cells;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"rowNumber : %d", self.rowNumber, nil];
}

- (void)setParentGrid:(ASDataGridView *)parentGrid
{
    _parentGrid = parentGrid;
    
    //Build all the cells based on the column definitions.
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.cells removeAllObjects];
    
    ASDataGridRowCell __block *firstCell = nil;
    ASDataGridRowCell __block *previousCell = nil;
    self.totalWidth = 0;
    
    [self.parentGrid.columnDefinitions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ASDataGridRowCell *cell = [[ASDataGridRowCell alloc]init];
        
        UITapGestureRecognizer *tapGest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cellTouchUpInside:)];
        [cell addGestureRecognizer:tapGest];
        
        [cell.textLabel setUserInteractionEnabled:NO];
        
        cell.frame = CGRectMake(0, 0, 0, self.parentGrid.rowHeight);
        cell.backgroundColor = [UIColor whiteColor];
        cell.layer.borderColor = [UIColor darkGrayColor].CGColor;
        cell.layer.borderWidth = 0.5f;
        
        self.totalWidth += [[obj valueForKey:@"width"] floatValue];
        
        [self addSubview:cell];
        [cell setParentRow:self];
        [self.cells addObject:cell];
        
        [cell setColumnDefinition:[self.parentGrid.columnDefinitions objectAtIndex:idx]];
        
        if (firstCell == nil)
            firstCell = cell;
        [previousCell setNextCell:cell];
        previousCell = cell;
        
    }];
    
    [firstCell setCellWidth:firstCell.cellWidth];
}

- (void)cellTouchUpInside:(id)sender
{
    ASDataGridRowCell *cell = (ASDataGridRowCell *)[sender view];
    
    BOOL isSelected = [cell.parentRow.parentGrid isRowNumberSelected:cell.rowNumber];
    
    if (isSelected)
        [self.parentGrid deselectRowNumber:self.rowNumber];
    else
        [self.parentGrid selectRowNumber:self.rowNumber];
    
    [self render];
    
    if (cell.columnDefinition.cellTapHandler != nil)
        cell.columnDefinition.cellTapHandler(cell, cell.value, cell.columnDefinition, self.rowNumber, cell.rowData, isSelected);
}

- (void)setRowNumber:(int)rowNumber
{
    _rowNumber = rowNumber;
    float rowTop = self.parentGrid.rowHeight * (rowNumber + 1);
    NSArray *rowData = nil;
    if (rowNumber >= 0)
        rowData = [self.parentGrid.sourceData rowDataForRowNumber:rowNumber];
    else
        rowData = [self.parentGrid.sourceData columnNames];

    [self.parentGrid.columnDefinitions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ASDataGridRowCell *cell = [self.cells objectAtIndex:idx];
        cell.rowNumber = rowNumber;
        
        cell.value = [rowData objectAtIndex:idx];
        
        cell.rowData = rowData;
        cell.columnDefinition = obj;
        [cell render];
    }];
    
    self.frame = CGRectMake(0, rowTop, self.totalWidth, self.parentGrid.rowHeight);
//    [self setNeedsDisplay];
}
@end

@implementation ASDataGridRowCell
- (void) setColumnDefinition:(ASDataGridColumnDefinition*)columnDefinition
{
    _columnDefinition = columnDefinition;
    [columnDefinition addObserver:self forKeyPath:@"width" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    [columnDefinition addObserver:self forKeyPath:@"cellRenderer" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"width"])
    {
        self.cellWidth = [[change valueForKey:@"new"]floatValue];
    }
    
    if ([keyPath isEqualToString:@"cellRenderer"])
    {
        [self render];
    }
}

- (void)render
{
    self.textLabel.text = nil;
    BOOL isSelected = [self.parentRow.parentGrid isRowNumberSelected:self.rowNumber];
    ASDataGridRowCellHandler cellRenderer = self.columnDefinition.cellRenderer;
    if (cellRenderer == nil)
    {
        self.textLabel.text = [self.value description];
        if (isSelected)
        {
            self.textLabel.textColor = [UIColor whiteColor];
            self.backgroundColor = [UIColor blueColor];
        }
        else
        {
            self.textLabel.textColor = [UIColor blackColor];
            self.backgroundColor = [UIColor whiteColor];
        }
    }
    else
        cellRenderer(self, self.value, self.columnDefinition, self.rowNumber, self.rowData, isSelected);
}

- (void)dealloc
{
    [self.columnDefinition removeObserver:self forKeyPath:@"width"];
    [self.columnDefinition removeObserver:self forKeyPath:@"cellRenderer"];
}

- (id) init
{
    self = [super init];
    if (self)
    {
        _cellWidth = 0;
        _cellLeft = 0;
        self.textLabel = [[UILabel alloc]init];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)setText:(NSString *)text
{
    self.textLabel.text = text;
}

- (void) setCellLeft:(CGFloat)cellLeft
{
    _cellLeft = cellLeft;
    [self setFrame:CGRectMake(cellLeft, self.frame.origin.y, self.cellWidth, self.frame.size.height)];
    [self updateNextCell];
}

- (void)setCellWidth:(CGFloat)cellWidth
{
    _cellWidth = cellWidth;
    [self setFrame:CGRectMake(self.cellLeft, self.frame.origin.y, self.cellWidth, self.frame.size.height)];
    [self.textLabel setFrame:CGRectMake(self.columnDefinition.cellPadding, 0.0f, self.cellWidth - self.columnDefinition.cellPadding * 2, self.frame.size.height)];
    [self updateNextCell];
}

- (void)updateNextCell
{
    _cellLeft = self.frame.origin.x;
    if (self.nextCell != nil)
    {
        [self.nextCell setFrame:CGRectMake(self.cellLeft + self.cellWidth, self.nextCell.frame.origin.y, self.nextCell.frame.size.width, self.nextCell.frame.size.height)];
        [self.nextCell updateNextCell];
    }
    else
    {
        self.parentRow.totalWidth = self.cellLeft + self.cellWidth;
        self.parentRow.frame = CGRectMake(self.parentRow.frame.origin.x, self.parentRow.frame.origin.y, self.parentRow.totalWidth, self.parentRow.frame.size.height);
    }
}

@end

@implementation ASDataGridView

- (BOOL)isRowNumberSelected:(int)rowNumber
{
    return [self.selectedRowNumbers containsObject:[NSNumber numberWithInt:rowNumber]];
}

- (ASDataGridRow *)visibleRowForRowNumber:(int)rowNumber
{
    for (ASDataGridRow *row in self.visibleRows)
    {
        if (row.rowNumber == rowNumber)
            return row;
    }
    return nil;
}

- (void)selectRowNumber:(int)rowNumber
{
    if (![self isRowNumberSelected:rowNumber])
    {
        [self.selectedRowNumbersInternal addObject:[NSNumber numberWithInt:rowNumber]];
     
        if (self.rowSelectionChanged != nil)
            self.rowSelectionChanged(self, rowNumber, [self.sourceData rowDataForRowNumber:rowNumber], YES);
        
        [[self visibleRowForRowNumber:rowNumber]render];
    }
}

- (void) deselectRowNumber:(int)rowNumber
{
    if ([self isRowNumberSelected:rowNumber])
    {
        [self.selectedRowNumbersInternal removeObject:[NSNumber numberWithInt:rowNumber]];
        
        if (self.rowSelectionChanged != nil)
            self.rowSelectionChanged(self, rowNumber, [self.sourceData rowDataForRowNumber:rowNumber], NO);
        
        [[self visibleRowForRowNumber:rowNumber]render];
    }
}

- (void)ensureViewInitialized
{
    if (self.visibleRows != nil)
        return;
    
    self.visibleRows = [[NSMutableArray alloc]init];
    self.availableRows = [[NSMutableArray alloc]init];
    
    self.scrollView = [[UIScrollView alloc]initWithFrame:self.frame];
    self.gridSubview = [[UIView alloc]initWithFrame:self.frame];
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.gridSubview];
    
    self.scrollView.delegate = self;
    
    [self.scrollView bringSubviewToFront:self.headerRow];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateVisibleRows];
    [self.headerRow setFrame:CGRectMake(0, self.scrollView.contentOffset.y, self.headerRow.frame.size.width, self.headerRow.frame.size.height)];
    [self.gridSubview bringSubviewToFront:self.headerRow];
}

- (void) updateVisibleRows
{
    CGRect visibleRect;
    visibleRect.origin = _scrollView.contentOffset;
    visibleRect.size = _scrollView.bounds.size;
    
    //Determine which rows should be displayed.
    float min = visibleRect.origin.y;
    float max = min + visibleRect.size.height;
    
    min = (int)((int)min / self.rowHeight) ;
    max = (int)((int)max / self.rowHeight) + 1;
    
    
    NSMutableArray *rowsToShift = [[NSMutableArray alloc]init];
    [self.visibleRows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj rowNumber] < min || [obj rowNumber] > max)
        {
            [obj removeFromSuperview];
            [rowsToShift addObject:obj];
        }
    }];
    
    [rowsToShift enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.visibleRows removeObject:obj];
        [self.availableRows addObject:obj];
    }];
    
    for (int rowNumber = min; rowNumber <= max; rowNumber++)
    {
        
        if (rowNumber >= self.sourceData.rowCount)
            break;
        
        BOOL found = NO;
        for (ASDataGridRow *row in self.visibleRows)
        {
            if (row.rowNumber == rowNumber)
            {
                found = YES;
                break;
            }
        }
        if (found == YES)
            continue;
        
        for (ASDataGridRow *row in self.visibleRows)
        {
            if (row.rowNumber == rowNumber)
            {
                found = YES;
                break;
            }
        }
        
        [self getRowInternal:rowNumber];
    }
}

- (IBAction)testResize:(id)sender {
    [self.columnDefinitions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        float n = [[obj valueForKey:@"width"]floatValue];
        n += 50.0f;
        [obj setValue:[NSNumber numberWithFloat:n] forKey:@"width"];
    }];
}

- (ASDataGridRow *)getRowInternal:(int)rowNumber
{
    ASDataGridRow *row = [self rowForRowNumber:rowNumber];
    if (row.parentGrid == nil)
        row.parentGrid = self;
    [self.availableRows removeObject:row];
    [self.visibleRows addObject:row];
    [self.gridSubview addSubview:row];
    [row setRowNumber:rowNumber];
    return row;
}

- (ASDataGridRow *)rowForRowNumber:(int)rowNumber
{
    ASDataGridRow *row = [self.availableRows lastObject];
    if (row == nil)
    {
        row = [[ASDataGridRow alloc]init];
    }
    return row;
}

//- (ASDataGridRow *)dequeueReusableRow
//{
//    ASDataGridRow *row = [self.availableRows lastObject];
//    //    [self.availableRows removeObject:row];
//    //    [self.visibleRows addObject:row];
//    return row;
//    //    if (row == nil)
//    //    {
//    //        row = [[ASDataGridRow alloc]init];
//    //        [row setParentGrid:self];
//    //    }
//    //    [self.gridSubview addSubview:row];
//    //    [row setRowNumber:rowNumber];
//    //    [self.visibleRows addObject:row];
//    //    return nil;
//}

- (NSArray *)selectedRowNumbers
{
    if (self.selectedRowNumbersInternal == nil)
        self.selectedRowNumbersInternal = [[NSMutableArray alloc]init];
    return self.selectedRowNumbersInternal;
}

- (void)setSourceData:(NSObject<ASDataGridViewDataSource> *)sourceData
{
    [self ensureViewInitialized];
    _sourceData = sourceData;
    [self reloadData];
}

- (NSArray *)columnNames
{
    return self.sourceData.columnNames;
}

- (float) rowHeight
{
    return 30.0f;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"width"])
    {
        float __block totalWidth = 0;
        [self.columnDefinitions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            totalWidth += [[obj valueForKey:@"width"] floatValue];
        }];
        
        [self.gridSubview setFrame:CGRectMake(0, 0, totalWidth, self.sourceData.rowCount * self.rowHeight)];
        [self.scrollView setContentSize:self.gridSubview.frame.size];
    }
}

- (void) prepareColumns:(NSArray *)columns
{
    NSMutableArray __block *cols = [[NSMutableArray alloc]initWithCapacity:[columns count]];
    UILabel *tmp = [[UILabel alloc]init];
    UIFont *theFont = tmp.font;
    
    if (self.columnDefinitions != nil)
    {
        [self.columnDefinitions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj removeObserver:self forKeyPath:@"width"];
            [obj removeObserver:self forKeyPath:@"cellRenderer"];
        }];
    }
    
    [columns enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ASDataGridColumnDefinition *def = nil;
        if ([obj isKindOfClass:[ASDataGridColumnDefinition class]])
        {
            def = obj;
        }
        else if ([obj isKindOfClass:[NSString class]])
        {
            def = [[ASDataGridColumnDefinition alloc]init];
            def.name = obj;
        }
        else
        {
            def = [[ASDataGridColumnDefinition alloc]init];
            [def setValuesForKeysWithDictionary:obj];
        }
        
        if (def.width <= 0.0f)
        {
            def.width = [def.name sizeWithFont:theFont].width + def.cellPadding * 2;
        }
        
        [cols setObject:def atIndexedSubscript:idx];
        [def addObserver:self forKeyPath:@"width" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
        [def addObserver:self forKeyPath:@"cellRenderer" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    }];

    self.columnDefinitions = cols;
}

- (void) reloadData
{
    if (self.columnDefinitions == nil || self.columnDefinitions.count == 0)
        [self prepareColumns:self.columnNames];
    
    if (self.gridSubview == nil)
        return;
    
    
    [self.gridSubview.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visibleRows removeAllObjects];
    [self.availableRows removeAllObjects];
    
    self.headerRow = [[ASDataGridRow alloc]init];
    self.headerRow.parentGrid = self;
    [self.gridSubview addSubview:self.headerRow];
    self.headerRow.frame = CGRectMake(10, 10, 800, 24.0f);
    [self.gridSubview bringSubviewToFront:self.headerRow];
    [self.headerRow setRowNumber:-1];
    
    
    [self.gridSubview setFrame:CGRectMake(0, 0, self.headerRow.totalWidth, self.sourceData.rowCount * self.rowHeight)];
    [self.scrollView setContentSize:self.gridSubview.frame.size];
    
    [self updateVisibleRows];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self reloadData];
}

@end
