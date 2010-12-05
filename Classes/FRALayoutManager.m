/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRAStandardHeader.h"

#import "FRALayoutManager.h"

@implementation FRALayoutManager

@synthesize showInvisibleCharacters;

- (id)init
{
	if (self = [super init]) {
		
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]], NSFontAttributeName, [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"InvisibleCharactersColourWell"]], NSForegroundColorAttributeName, nil];
		unichar tabUnichar = 0x00AC;
		tabCharacter = [[NSString alloc] initWithCharacters:&tabUnichar length:1];
		unichar newLineUnichar = 0x00B6;
		newLineCharacter = [[NSString alloc] initWithCharacters:&newLineUnichar length:1];
		unichar spaceUnichar = 0x02FD;
		spaceCharacter = [[NSString alloc] initWithCharacters:&spaceUnichar length:1];
		
		[self setShowInvisibleCharacters:[[FRADefaults valueForKey:@"ShowInvisibleCharacters"] boolValue]];
		[self setAllowsNonContiguousLayout:YES]; // Setting this to YES sometimes causes "an extra toolbar" and other graphical glitches to sometimes appear in the text view when one sets a temporary attribute, reported as ID #5832329 to Apple
		
		NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
		[defaultsController addObserver:self forKeyPath:@"values.TextFont" options:NSKeyValueObservingOptionNew context:@"FontOrColourValueChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.InvisibleCharactersColourWell" options:NSKeyValueObservingOptionNew context:@"FontOrColourValueChanged"];

	}
	return self;
}

- (void)dealloc
{
	[spaceCharacter release];
	[tabCharacter release];
	[newLineCharacter release];
	[attributes release];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(NSString *)context isEqualToString:@"FontOrColourValueChanged"]) {
		[attributes release];
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]], NSFontAttributeName, [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"InvisibleCharactersColourWell"]], NSForegroundColorAttributeName, nil];
		[[self firstTextView] setNeedsDisplay:YES];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (void)drawGlyphsForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)containerOrigin
{
    if (showInvisibleCharacters) {
		
		NSString *completeString = [[self textStorage] string];
		
		unichar characters[glyphRange.length];
		[completeString getCharacters:&characters[0] range:glyphRange];
		NSInteger index;
		for (index = 0; index < glyphRange.length; index++) {
			NSString *characterToDraw;
			switch (characters[index]) {
				case '\t':
					characterToDraw = tabCharacter;
					break;
				case '\r':
				case '\n':
					characterToDraw = newLineCharacter;
					break;
				case ' ':
					characterToDraw = spaceCharacter;
					break;
				default:
					continue;
			}
			NSInteger characterIndex = index + glyphRange.location;
			NSPoint pointToDrawAt = [self locationForGlyphAtIndex:characterIndex];
			NSRect glyphFragment = [self lineFragmentRectForGlyphAtIndex:characterIndex effectiveRange:NULL];
			pointToDrawAt.x += glyphFragment.origin.x;
			// Workaround redraw issues
			pointToDrawAt.y = glyphFragment.origin.y - 1.0f;
			[characterToDraw drawAtPoint:pointToDrawAt withAttributes:attributes];
		}
    } 
	
    [super drawGlyphsForGlyphRange:glyphRange atPoint:containerOrigin];
}

@end
