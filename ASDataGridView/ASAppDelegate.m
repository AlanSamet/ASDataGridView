//
//  ASAppDelegate.m
//  ASDataGridView
//
//  Created by Alan Samet on 7/28/13.
//  Copyright (c) 2013 Panalucent LLC. All rights reserved.
//

#import "ASAppDelegate.h"
#import "ASDataGridView.h"
#import "ASDataGridViewController.h"
#import <stdlib.h>

@implementation ASAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (void)prepareUI
{
    self.tabBarController = [[UITabBarController alloc]init];
    
    ASDataGridViewController *sample1 = [[ASDataGridViewController alloc]initWithNibName:nil bundle:nil];
    sample1.title = @"Simple";
    
    ASDataGridView *view1 = (ASDataGridView *)sample1.view;
    ASSimpleDataGridViewDataSource *simpleSource1 = [[ASSimpleDataGridViewDataSource alloc]init];
    [simpleSource1 setSourceData:[self buildSampleGridData:20 withRowCount:200]];
    [view1 setSourceData:simpleSource1];
    
    
    ASDataGridViewController *sample2 = [[ASDataGridViewController alloc]initWithNibName:nil bundle:nil];
    sample2.title = @"CustomRender";
    
    ASDataGridView *view2 = (ASDataGridView *)sample2.view;
    
    ASSimpleDataGridViewDataSource *simpleSource2 = [[ASSimpleDataGridViewDataSource alloc]init];
    [simpleSource2 setSourceData:[self buildSampleGridData:20 withRowCount:200]];
    [view2 setSourceData:simpleSource2];
    
    view2.rowSelectionChanged = ^(ASDataGridView *sender, int rowNumber, NSArray *rowData, BOOL isSelected)
    {
        //Let's make this single selection.
        if (isSelected)
        {
            NSArray *selectedRowNumbers = [sender.selectedRowNumbers copy];
            [selectedRowNumbers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
               if (![obj isEqual:[NSNumber numberWithInt:rowNumber]])
               {
                   [sender deselectRowNumber:[obj intValue]];
               }
            }];
        }
        NSLog(@"%d:%d:%@", rowNumber, isSelected, rowData);
    };
    
    [view2.columnDefinitions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ASDataGridColumnDefinition *colDef = (ASDataGridColumnDefinition *)obj;
        
        colDef.cellRenderer = ^(ASDataGridRowCell * cell, id cellValue, ASDataGridColumnDefinition *columnDefinition, int rowNumber, NSArray *rowData, BOOL rowIsSelected)
        {
            cell.backgroundColor = [UIColor colorWithRed:arc4random_uniform(1000)/1000.0f green:arc4random_uniform(1000)/1000.0f blue:arc4random_uniform(1000)/1000.0f alpha:1.0f];
            cell.textLabel.text = [cellValue description];

            if (rowIsSelected)
            {
                cell.layer.borderColor = [UIColor blueColor].CGColor;
                cell.layer.borderWidth = 2.0f;
                cell.textLabel.textColor = [UIColor whiteColor];
            }
            else
            {
                cell.layer.borderColor = [UIColor darkGrayColor].CGColor;
                cell.layer.borderWidth = 0.5f;
                cell.textLabel.textColor = [UIColor blackColor];
            }
            if (rowNumber == -1)
                cell.textLabel.text = [obj name];
        };
    }];
    
    ASDataGridViewController *sample3 = [[ASDataGridViewController alloc]initWithNibName:nil bundle:nil];
    sample3.title = @"CoreData";
    
    ASDataGridView *view3 = (ASDataGridView *)sample3.view;
    
    ASFetchedResultsDataGridViewDataSource *dataSource3 = [[ASFetchedResultsDataGridViewDataSource alloc]init];
    [dataSource3 setFetchedResultsController:[self createFetchedResultsController]];

    [view3 setSourceData:dataSource3];
    
    self.tabBarController.viewControllers = @[sample1, sample2, sample3];
    
    self.window.rootViewController = self.tabBarController;
}

- (NSFetchedResultsController *) createFetchedResultsController
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SampleEntity" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"attribute1" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    
    NSError *error = nil;
    [aFetchedResultsController performFetch:&error];
    NSLog(@"%@", error);
    return aFetchedResultsController;
}

- (NSDictionary *)buildSampleGridData:(int)colCount withRowCount:(int)rowCount
{
    NSMutableArray *cols = [[NSMutableArray alloc]initWithCapacity:colCount];
    NSMutableArray *rows = [[NSMutableArray alloc]initWithCapacity:rowCount];
    
    for (int i = 0; i < colCount; i++)
    {
        [cols setObject:[NSString stringWithFormat:@"Column %d", i] atIndexedSubscript:i];
    }
    
    for (int r = 0; r < rowCount; r++)
    {
        NSMutableArray *rowData = [[NSMutableArray alloc]initWithCapacity:colCount];
        for (int c = 0; c < colCount; c++)
        {
            [rowData setObject:[NSString stringWithFormat:@"r%dc%d", r, c] atIndexedSubscript:c];
        }
        [rows setObject:rowData atIndexedSubscript:r];
    }
    
    return @{@"columns":cols, @"data":rows};
}

- (void)verifyDataStoreHasData
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SampleEntity" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error = nil;
    if ([self.managedObjectContext countForFetchRequest:fetchRequest error:&error] == 0)
    {
        for (int i = 0; i < 10000; i++)
        {
            NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:@"SampleEntity" inManagedObjectContext:self.managedObjectContext];
            [obj setValue:[NSNumber numberWithInt:i] forKey:@"attribute1"];
            [obj setValue:[NSString stringWithFormat:@"Value %d", i] forKey:@"attribute2"];
        }
        [self.managedObjectContext save:&error];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self prepareUI];
    [self verifyDataStoreHasData];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ASDataGridView" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ASDataGridView.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
