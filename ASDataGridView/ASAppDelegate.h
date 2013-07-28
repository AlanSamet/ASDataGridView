//
//  ASAppDelegate.h
//  ASDataGridView
//
//  Created by Alan on 7/28/13.
//  Copyright (c) 2013 Panalucent LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ASAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
