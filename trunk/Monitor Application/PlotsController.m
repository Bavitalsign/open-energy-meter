//
//  PlotsController.m
//  PropStream
//
//  Created by Jay Kickliter on 3/3/11.
//  Copyright 2011 Chasing 'trons. All rights reserved.
//

static NSString * const CURRENT_PLOT = @"Current Plot";
static NSString * const VOLTAGE_PLOT = @"Voltage Plot";
static NSString * const ENERGY_PLOT  = @"Energy Plot";

#import <CorePlot/CorePlot.h>
#import "PlotsController.h"


@implementation PlotsController

-(void)dealloc 
{
	[currentPlotData release];
	[voltagePlotData release];
	[energyPlotData release];
	[currentPlot release];
	[voltagePlot release];
	[energyPlot release];
	[super dealloc];
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	
	currentPlotData = [[NSMutableArray alloc] init];
	voltagePlotData = [[NSMutableArray alloc] init];
	energyPlotData = [[NSMutableArray alloc] init];
	

	// Create graph from theme
	currentPlot = [(CPXYGraph *)[CPXYGraph alloc] initWithFrame:CGRectZero];
	voltagePlot = [(CPXYGraph *)[CPXYGraph alloc] initWithFrame:CGRectZero];
	energyPlot = [(CPXYGraph *)[CPXYGraph alloc]  initWithFrame:CGRectZero];
	
	CPTheme *theme = [CPTheme themeNamed:kCPSlateTheme];
	[currentPlot applyTheme:theme];	
	[currentPlot setTitle: @"Current Waveform"];
	[currentPlot setTitleDisplacement: CGPointMake(0, -10)];
	
	[voltagePlot applyTheme: theme];
	voltagePlot.title = @"Voltage Waveform";
	voltagePlot.titleDisplacement = CGPointMake(0, -10);
	
	[energyPlot  applyTheme:theme];
	energyPlot.title = @"Power";
	energyPlot.titleDisplacement = CGPointMake(0, -10);
	
	
	currentHostView.hostedLayer = currentPlot;
	voltageHostView.hostedLayer = voltagePlot;
	energyHostView.hostedLayer	= energyPlot;
	
	// Setup scatter plot space
	currentPlotSpace = (CPXYPlotSpace *)currentPlot.defaultPlotSpace;
	currentPlotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromInt(0) length:CPDecimalFromInt(99)];
	currentPlotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromInt(-2048) length:CPDecimalFromFloat(4096)];

	
	
	// Setup scatter plot space
	voltagePlotSpace = (CPXYPlotSpace *)voltagePlot.defaultPlotSpace;
	voltagePlotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromInt(0) length:CPDecimalFromInt(99)];
	voltagePlotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromInt(-2048) length:CPDecimalFromFloat(4096)];
	
	// Setup scatter plot space
	energyPlotSpace = (CPXYPlotSpace *)energyPlot.defaultPlotSpace;
	energyPlotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0) length:CPDecimalFromInt(99)];
	energyPlotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(-0.1) length:CPDecimalFromFloat(2.2)];
	energyPlotSpace.allowsUserInteraction = YES;
	energyPlotSpace.delegate = self;
	
	// Axes
	CPXYAxisSet *axisSet = (CPXYAxisSet *)currentPlot.axisSet;
	CPXYAxis *x = axisSet.xAxis;
	x.majorTickLineStyle = nil;
	x.majorIntervalLength = CPDecimalFromString(@"25");
	x.orthogonalCoordinateDecimal = CPDecimalFromInt(0);
	x.minorTicksPerInterval = 0;
	x.labelFormatter = nil;
															 
	CPXYAxis *y = axisSet.yAxis;
	y.majorIntervalLength = CPDecimalFromInt(1);
	y.minorTicksPerInterval = 5;
	y.orthogonalCoordinateDecimal = CPDecimalFromFloat(-100);
	
	
	// Axes
	axisSet = (CPXYAxisSet *)voltagePlot.axisSet;
	x = axisSet.xAxis;
	x.majorTickLineStyle = nil;
	x.majorIntervalLength = CPDecimalFromString(@"25");
	x.orthogonalCoordinateDecimal = CPDecimalFromInt(0);
	x.minorTicksPerInterval = 0;
	x.labelFormatter = nil;
	
	y = axisSet.yAxis;
	y.majorIntervalLength = CPDecimalFromString(@"1");
	y.minorTicksPerInterval = 5;
	y.orthogonalCoordinateDecimal = CPDecimalFromFloat(-100);
	
	// Axes
	axisSet = (CPXYAxisSet *)energyPlot.axisSet;
	x = axisSet.xAxis;
	x.majorIntervalLength = CPDecimalFromString(@"25");
	x.orthogonalCoordinateDecimal = CPDecimalFromInt(0);
	x.minorTicksPerInterval = 0;
	
	y = axisSet.yAxis;
	y.majorIntervalLength = CPDecimalFromString(@"1000");
	y.minorTicksPerInterval = 5;
	y.orthogonalCoordinateDecimal = CPDecimalFromFloat(0);	
	
	
	
	// Create a plot that uses the data source method
	voltageDataSourceLinePlot = [[[CPScatterPlot alloc] init] autorelease];
	voltageDataSourceLinePlot.identifier = VOLTAGE_PLOT;
	voltageDataSourceLinePlot.dataLineStyle.lineWidth = 2.f;
	voltageDataSourceLinePlot.dataLineStyle.lineColor = [CPColor blueColor];
	voltageDataSourceLinePlot.dataSource = self;
	[voltagePlot addPlot:voltageDataSourceLinePlot];
	
	// Create a plot that uses the data source method
	currentDataSourceLinePlot = [[[CPScatterPlot alloc] init] autorelease];
	currentDataSourceLinePlot.identifier = CURRENT_PLOT;
	currentDataSourceLinePlot.dataLineStyle.lineWidth = 2.f;
	currentDataSourceLinePlot.dataLineStyle.lineColor = [CPColor blueColor];
	currentDataSourceLinePlot.dataSource = self;
	[currentPlot addPlot:currentDataSourceLinePlot];
	
	
	
	// Create a plot that uses the data source method
	energyDataSourceLinePlot = [[[CPScatterPlot alloc] init] autorelease];
	energyDataSourceLinePlot.identifier = ENERGY_PLOT;
	energyDataSourceLinePlot.dataLineStyle.lineWidth = 2.f;
	energyDataSourceLinePlot.dataLineStyle.lineColor = [CPColor blueColor];
	energyDataSourceLinePlot.dataSource = self;
	[energyPlot addPlot:energyDataSourceLinePlot];
}

#pragma mark -
#pragma mark Plot Data Source Methods




-(NSUInteger)numberOfRecordsForPlot:(CPPlot *)plot
{
	NSUInteger count = 0;
	
	if ([(NSString *)plot.identifier isEqualToString:CURRENT_PLOT]) {
		count = [currentPlotData count];
	} else if ([(NSString *)plot.identifier isEqualToString:VOLTAGE_PLOT]) {
		count = [voltagePlotData count];
	} else {
		count = [energyPlotData count];
	}

	return count;
}

-(NSNumber *)numberForPlot:(CPPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSNumber *num = nil;
	if ([(NSString *)plot.identifier isEqualToString:CURRENT_PLOT]) {
		switch (fieldEnum) {
			case CPScatterPlotFieldX:
				num = [NSNumber numberWithUnsignedInt:index];
				break;
			case CPScatterPlotFieldY:
				num = [currentPlotData objectAtIndex:index];				
				break;
			default:
				break;
		}
	} else if ([(NSString *)plot.identifier isEqualToString:VOLTAGE_PLOT]) {
		switch (fieldEnum) {
			case CPScatterPlotFieldX:
				num = [NSNumber numberWithUnsignedInt:index];
				break;
			case CPScatterPlotFieldY:
				num = [voltagePlotData objectAtIndex:index];
				break;
			default:
				break;
		}
	} else if ([(NSString *)plot.identifier isEqualToString:ENERGY_PLOT]) {
			switch (fieldEnum) {
				case CPScatterPlotFieldX:
					num = [NSNumber numberWithUnsignedInt:index];
					break;
				case CPScatterPlotFieldY:
					num = [energyPlotData objectAtIndex:index];
					break;
				default:
					break;
			}
	}
	
	return num;
}





- (void)addNewData:(NSData *)data
{
	short			 tempShort;
	NSInteger	 i;
	char			 packetType;
	char			 reloadFlag;
	NSNumber	 *num = nil;
	id				 plotDataToUpdate;
	id				 plotToReload;

	[data getBytes: &packetType range: NSMakeRange(0, 1)];
	[data getBytes: &reloadFlag range: NSMakeRange(1, 1)];	
	
	switch (packetType) {
		case 0x63:
			plotDataToUpdate	= currentPlotData;
			plotToReload			= currentDataSourceLinePlot;
			break;
		case 0x76:
			plotDataToUpdate  = voltagePlotData;
			plotToReload			=	voltageDataSourceLinePlot;
			break;
		default:
			return;
	}
	
	for (i = 2; i < [data length]; i += 2)
	{
		[data getBytes:&tempShort range: NSMakeRange(i,2)];
		num = [NSNumber numberWithShort: tempShort];
		[plotDataToUpdate addObject:num];
	}
	i = [plotDataToUpdate count];
	if (i > 100) {
		[plotDataToUpdate removeObjectsInRange: NSMakeRange(0, i-100)];
		NSLog(@"%@", plotDataToUpdate);
	}
	
	if (reloadFlag == 1) {
		[plotToReload reloadData];
	}
}

- (void)addNewEnergyPlotPoint:(float)value
{
	NSNumber *num = [NSNumber numberWithFloat: value/1000];
	[energyPlotData addObject: num];
	[energyDataSourceLinePlot reloadData];
}




@end