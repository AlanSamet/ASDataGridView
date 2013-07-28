//
//  ASDataGridView.h
//
//  Created by Alan Samet on 7/28/13.
//  Copyright (c) 2013 Panalucent LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ASDataGridRow : UIView
@end

@interface ASDataGridView : UIScrollView
@end

@protocol ASDataGridViewDataSource
- (NSArray *)rowDataForRowNumber:(int)rowNumber;
- (NSArray *)columnNames;
- (int) rowCount;
@end

typedef void (^ASDataGridRowHandler) (ASDataGridView *sender, int rowNumber, NSArray *rowData, BOOL rowIsSelected);

@interface ASSimpleDataGridViewDataSource : NSObject <ASDataGridViewDataSource>
@property (strong, nonatomic) NSDictionary *sourceData;
@end

@interface ASFetchedResultsDataGridViewDataSource : NSObject <ASDataGridViewDataSource>
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@end

@interface ASDataGridView ()
@property (strong, nonatomic) NSObject<ASDataGridViewDataSource> *sourceData;
@property (strong, nonatomic) NSArray *columnDefinitions;
@property (strong, nonatomic) ASDataGridRow *headerRow;
@property (assign, nonatomic) CGFloat rowHeight;
@property (nonatomic, strong) ASDataGridRowHandler rowSelectionChanged;

- (BOOL) isRowNumberSelected:(int)rowNumber;
- (void) selectRowNumber:(int)rowNumber;
- (void) deselectRowNumber:(int)rowNumber;
- (NSArray *)selectedRowNumbers;
//- (NSArray *)rows;
@end

@interface ASDataGridRow ()
@property (strong, nonatomic) NSMutableArray *cells;
@property (weak, nonatomic) ASDataGridView *parentGrid;
@property (nonatomic) int rowNumber;
@property (nonatomic) float totalWidth;
@end

@interface ASDataGridRowCell : UIView

@end

@interface ASDataGridColumnDefinition : NSObject

@end

typedef void (^ASDataGridRowCellHandler) (ASDataGridRowCell * cell, id cellValue, ASDataGridColumnDefinition *columnDefinition, int rowNumber, NSArray *rowData, BOOL rowIsSelected);

@interface ASDataGridColumnDefinition ()
@property (nonatomic) CGFloat width;
@property (strong, nonatomic) NSString *name;
@property (nonatomic, strong) ASDataGridRowCellHandler cellRenderer;
@property (nonatomic, strong) ASDataGridRowCellHandler cellTapHandler;
@property (assign, nonatomic) float cellPadding;
@end

@interface ASDataGridRowCell ()
@property (nonatomic)  CGFloat cellLeft;
@property (nonatomic) CGFloat cellWidth;
@property (weak, nonatomic) ASDataGridRowCell *nextCell;
@property (strong, nonatomic) UILabel *textLabel;
@property (strong, nonatomic) ASDataGridColumnDefinition *columnDefinition;
@property (weak, nonatomic) ASDataGridRow *parentRow;
- (void)updateNextCell;
@end