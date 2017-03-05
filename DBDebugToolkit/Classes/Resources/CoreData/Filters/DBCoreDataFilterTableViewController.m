//
//  DBCoreDataFilterTableViewController.m
//  Pods
//
//  Created by Dariusz Bukowski on 04.03.2017.
//
//

#import "DBCoreDataFilterTableViewController.h"
#import "DBOptionsListTableViewController.h"
#import "NSBundle+DBDebugToolkit.h"
#import "DBMenuSwitchTableViewCell.h"
#import "DBTextViewTableViewCell.h"

static NSString *const DBCoreDataFilterTableViewControllerOptionCellIdentifier = @"DBOptionTableViewCell";
static NSString *const DBCoreDataFilterTableViewControllerSwitchCellIdentifier = @"DBMenuSwitchTableViewCell";
static NSString *const DBCoreDataFilterTableViewControllerTextViewCellIdentifier = @"DBTextViewTableViewCell";

@interface DBCoreDataFilterTableViewController () <DBOptionsListTableViewControllerDelegate, DBOptionsListTableViewControllerDataSource, DBMenuSwitchTableViewCellDelegate, UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *saveButton;
@property (nonatomic, assign) BOOL didSelectAttribute;

@end

@implementation DBCoreDataFilterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshSaveButton];
    NSBundle *bundle = [NSBundle debugToolkitBundle];
    [self.tableView registerNib:[UINib nibWithNibName:@"DBMenuSwitchTableViewCell" bundle:bundle]
         forCellReuseIdentifier:DBCoreDataFilterTableViewControllerSwitchCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"DBTextViewTableViewCell" bundle:bundle]
         forCellReuseIdentifier:DBCoreDataFilterTableViewControllerTextViewCellIdentifier];
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSInteger valueCellRow = [self.tableView numberOfRowsInSection:0] - 1;
    UITableViewCell *valueCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:valueCellRow
                                                                                          inSection:0]];
    if ([valueCell isKindOfClass:[DBTextViewTableViewCell class]]) {
        DBTextViewTableViewCell *textViewCell = (DBTextViewTableViewCell *)valueCell;
        [textViewCell.textView becomeFirstResponder];
    }
}

- (IBAction)closeButtonAction:(id)sender {
    [self.delegate filterTableViewControllerDidTapClose:self];
}

#pragma mark - Save button

- (IBAction)saveButtonAction:(id)sender {
    self.filter.value = [self properValueString];
    [self.delegate filterTableViewController:self didTapSaveWithFilter:self.filter];
}

- (void)refreshSaveButton {
    BOOL isAttributeNumeric = self.filter.attribute != NSStringAttributeType;
    BOOL isInputProper = isAttributeNumeric ? [self isValueAProperNumber] : self.filter.value.length > 0;
    self.saveButton.enabled = isInputProper;
}

- (BOOL)isValueAProperNumber {
    return [self numberFromString:self.filter.value] != nil;
}

- (NSString *)properValueString {
    if (self.filter.attribute.attributeType == NSStringAttributeType) {
        return self.filter.value;
    }
    NSNumber *number = [self numberFromString:self.filter.value];
    return [number stringValue];
}

- (NSNumber *)numberFromString:(NSString *)value {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setDecimalSeparator:@"."];
    return [numberFormatter numberFromString:self.filter.value];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row + 1 < [self tableView:tableView numberOfRowsInSection:indexPath.section]) {
        [self handleSelectingOptionCellWithRow:indexPath.row];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filter.availableOperators.count < 2 ? 2 : 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row + 1 == [self tableView:tableView numberOfRowsInSection:indexPath.section]) {
        return [self valueCell];
    } else {
        return [self optionCellWithRow:indexPath.row];
    }
}

#pragma mark - DBOptionsListTableViewControllerDelegate

- (void)optionsListTableViewController:(DBOptionsListTableViewController *)optionsListTableViewController didSelectOptionAtIndex:(NSInteger)optionIndex {
    if (self.didSelectAttribute) {
        self.filter.attribute = self.attributes[optionIndex];
        [self refreshSaveButton];
    } else {
        self.filter.filterOperator = self.filter.availableOperators[optionIndex];
    }
    [self.tableView reloadData];
}

#pragma mark - DBOptionsListTableViewControllerDataSource

- (NSInteger)selectedIndexInOptionsListTableViewController:(DBOptionsListTableViewController *)optionsListTableViewController {
    if (self.didSelectAttribute) {
        return [self.attributes indexOfObject:self.filter.attribute];
    } else {
        return [self.filter.availableOperators indexOfObject:self.filter.filterOperator];
    }
}

- (NSInteger)numberOfOptionsInOptionsListTableViewController:(DBOptionsListTableViewController *)optionsListTableViewController {
    return self.didSelectAttribute ? self.attributes.count : self.filter.availableOperators.count;
}

- (NSString *)optionsListTableViewController:(DBOptionsListTableViewController *)optionsListTableViewController titleAtIndex:(NSInteger)index {
    if (self.didSelectAttribute) {
        NSAttributeDescription *attribute = self.attributes[index];
        return attribute.name;
    } else {
        DBCoreDataFilterOperator *operator = self.filter.availableOperators[index];
        return operator.displayName;
    }
}

#pragma mark - DBMenuSwitchTableViewCellDelegate

- (void)menuSwitchTableViewCell:(DBMenuSwitchTableViewCell *)menuSwitchTableViewCell didSetOn:(BOOL)isOn {
    self.filter.value = [@(isOn) stringValue];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    CGPoint currentContentOffset = self.tableView.contentOffset;
    [UIView setAnimationsEnabled:NO];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:YES];
    [self.tableView setContentOffset:currentContentOffset animated:NO];
    self.filter.value = textView.text;
    [self refreshSaveButton];
}

#pragma mark - Private methods

#pragma mark - - Cells

- (UITableViewCell *)valueCell {
    if (self.filter.attribute.attributeType == NSBooleanAttributeType) {
        DBMenuSwitchTableViewCell *switchTableViewCell = [self.tableView dequeueReusableCellWithIdentifier:DBCoreDataFilterTableViewControllerSwitchCellIdentifier];
        switchTableViewCell.titleLabel.text = @"value";
        switchTableViewCell.valueSwitch.on = [self.filter.value boolValue];
        switchTableViewCell.delegate = self;
        return switchTableViewCell;
    } else {
        DBTextViewTableViewCell *textViewCell = [self.tableView dequeueReusableCellWithIdentifier:DBCoreDataFilterTableViewControllerTextViewCellIdentifier];
        textViewCell.titleLabel.text = @"value";
        textViewCell.textView.text = self.filter.value;
        textViewCell.textView.delegate = self;
        textViewCell.textView.keyboardType = self.filter.attribute.attributeType == NSStringAttributeType ? UIKeyboardTypeDefault : UIKeyboardTypeNumbersAndPunctuation;
        return textViewCell;
    }
}

- (UITableViewCell *)optionCellWithRow:(NSInteger)row {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DBCoreDataFilterTableViewControllerOptionCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:DBCoreDataFilterTableViewControllerOptionCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = row == 0 ? self.filter.attribute.name : self.filter.filterOperator.displayName;
    return cell;
}

#pragma mark - - Selection

- (void)handleSelectingOptionCellWithRow:(NSInteger)row {
    self.didSelectAttribute = row == 0;
    NSBundle *bundle = [NSBundle debugToolkitBundle];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DBOptionsListTableViewController" bundle:bundle];
    DBOptionsListTableViewController *optionsListTableViewController = [storyboard instantiateInitialViewController];
    optionsListTableViewController.delegate = self;
    optionsListTableViewController.dataSource = self;
    optionsListTableViewController.title = row == 0 ? @"Attribute" : @"Operator";
    [self.navigationController pushViewController:optionsListTableViewController animated:YES];
}

@end