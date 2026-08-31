import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fi'),
    Locale('sv'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @titleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleFieldLabel;

  /// No description provided for @titleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequiredError;

  /// No description provided for @nameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequiredError;

  /// No description provided for @labelOptional.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get labelOptional;

  /// No description provided for @labelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mom, Dad — helps tell parents apart'**
  String get labelHint;

  /// No description provided for @labelHintGeneric.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mom, Dad, Grandma'**
  String get labelHintGeneric;

  /// No description provided for @yourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @emailRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequiredError;

  /// No description provided for @emailInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalidError;

  /// No description provided for @passwordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequiredError;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @notInFamilyYet.
  ///
  /// In en, this message translates to:
  /// **'You\'re not part of a family yet.'**
  String get notInFamilyYet;

  /// No description provided for @familyMemberFallback.
  ///
  /// In en, this message translates to:
  /// **'Family member'**
  String get familyMemberFallback;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @copyCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCodeTooltip;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @homeNav.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNav;

  /// No description provided for @calendarNav.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarNav;

  /// No description provided for @familyNav.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyNav;

  /// No description provided for @freeTimeNav.
  ///
  /// In en, this message translates to:
  /// **'Free time'**
  String get freeTimeNav;

  /// No description provided for @groupsNav.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsNav;

  /// No description provided for @analyticsNav.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsNav;

  /// No description provided for @profileNav.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileNav;

  /// No description provided for @settingsNav.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsNav;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'FamilyPulse Login'**
  String get loginTitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginRegisterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register here.'**
  String get loginRegisterPrompt;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @confirmEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm email'**
  String get confirmEmailLabel;

  /// No description provided for @confirmEmailRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email'**
  String get confirmEmailRequiredError;

  /// No description provided for @emailsDontMatchError.
  ///
  /// In en, this message translates to:
  /// **'Emails don\'t match'**
  String get emailsDontMatchError;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequiredError;

  /// No description provided for @passwordTooShortError.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordTooShortError;

  /// No description provided for @passwordsDontMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDontMatchError;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// No description provided for @loginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in.'**
  String get loginPrompt;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Family life isn\'t missing another group chat.'**
  String get welcomeTagline;

  /// No description provided for @welcomePitch.
  ///
  /// In en, this message translates to:
  /// **'It\'s missing a heartbeat. FamilyPulse turns scattered texts, forgotten pickups, and \"wait — who\'s free Saturday?\" into one shared rhythm: a live calendar, a real-time pulse of everyone\'s day, and zero double-booked soccer practice.'**
  String get welcomePitch;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @logInButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logInButton;

  /// No description provided for @familyChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get familyChoiceTitle;

  /// No description provided for @createFamilyButton.
  ///
  /// In en, this message translates to:
  /// **'Create a family'**
  String get createFamilyButton;

  /// No description provided for @joinFamilyButton.
  ///
  /// In en, this message translates to:
  /// **'Join a family'**
  String get joinFamilyButton;

  /// No description provided for @joinFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a family'**
  String get joinFamilyTitle;

  /// No description provided for @familyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Family code'**
  String get familyCodeLabel;

  /// No description provided for @familyCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Ask a family member for their family code.'**
  String get familyCodeHelper;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @fillBothFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both fields.'**
  String get fillBothFieldsError;

  /// No description provided for @joinFamilyAction.
  ///
  /// In en, this message translates to:
  /// **'Join family'**
  String get joinFamilyAction;

  /// No description provided for @createFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a family'**
  String get createFamilyTitle;

  /// No description provided for @familyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyNameLabel;

  /// No description provided for @familyCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Family created'**
  String get familyCreatedTitle;

  /// Shown after creating a family, with the family's join code.
  ///
  /// In en, this message translates to:
  /// **'Share this code so others can join:\n\n{familyId}'**
  String shareCodeMessage(String familyId);

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @createFamilyAction.
  ///
  /// In en, this message translates to:
  /// **'Create family'**
  String get createFamilyAction;

  /// No description provided for @familyGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Groups'**
  String get familyGroupsTitle;

  /// No description provided for @couldNotLoadGroupsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load groups — {error}'**
  String couldNotLoadGroupsError(String error);

  /// No description provided for @unknownMember.
  ///
  /// In en, this message translates to:
  /// **'Unknown member'**
  String get unknownMember;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups yet. Make one for things like \"Kids\" or \"Chores squad\" to organize who\'s involved in what.'**
  String get noGroupsYet;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroup;

  /// No description provided for @deleteGroupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroupTooltip;

  /// No description provided for @deleteGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete group?'**
  String get deleteGroupTitle;

  /// Confirmation body before deleting a group.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed for everyone.'**
  String deleteGroupContent(String name);

  /// No description provided for @couldNotDeleteGroupError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete group — {error}'**
  String couldNotDeleteGroupError(String error);

  /// No description provided for @noMembersYetGroup.
  ///
  /// In en, this message translates to:
  /// **'No members yet.'**
  String get noMembersYetGroup;

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameLabel;

  /// No description provided for @groupNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get groupNameRequiredError;

  /// No description provided for @membersLabel.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersLabel;

  /// No description provided for @noFamilyMembersFoundYet.
  ///
  /// In en, this message translates to:
  /// **'No family members found yet.'**
  String get noFamilyMembersFoundYet;

  /// No description provided for @couldNotSaveGroupError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save group — {error}'**
  String couldNotSaveGroupError(String error);

  /// No description provided for @freeTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Time'**
  String get freeTimeTitle;

  /// No description provided for @previousDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDayTooltip;

  /// No description provided for @nextDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDayTooltip;

  /// No description provided for @minDuration30.
  ///
  /// In en, this message translates to:
  /// **'30 min+'**
  String get minDuration30;

  /// No description provided for @minDuration60.
  ///
  /// In en, this message translates to:
  /// **'1 hr+'**
  String get minDuration60;

  /// No description provided for @minDuration120.
  ///
  /// In en, this message translates to:
  /// **'2 hr+'**
  String get minDuration120;

  /// No description provided for @couldNotFindMembers.
  ///
  /// In en, this message translates to:
  /// **'Could not find any family members.'**
  String get couldNotFindMembers;

  /// No description provided for @noFreeWindow.
  ///
  /// In en, this message translates to:
  /// **'No window that long, free for everyone, between 7 AM and 9 PM on this day. Try a shorter minimum or another day.'**
  String get noFreeWindow;

  /// No description provided for @freeForEveryone.
  ///
  /// In en, this message translates to:
  /// **'{duration} minutes, free for everyone'**
  String freeForEveryone(int duration);

  /// No description provided for @scheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleButton;

  /// No description provided for @scheduleAtTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule at {time}'**
  String scheduleAtTitle(String time);

  /// No description provided for @freeTimeRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get freeTimeRetryButton;

  /// No description provided for @freeSlotsFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count} free periods found'**
  String freeSlotsFoundCount(int count);

  /// No description provided for @couldNotCreateEventError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create event — {error}'**
  String couldNotCreateEventError(String error);

  /// No description provided for @couldNotLoadFamilyMembersError.
  ///
  /// In en, this message translates to:
  /// **'Could not load family members — {error}'**
  String couldNotLoadFamilyMembersError(String error);

  /// No description provided for @couldNotLoadYourFamilyError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your family — {error}'**
  String couldNotLoadYourFamilyError(String error);

  /// No description provided for @couldNotLoadFreeTimeError.
  ///
  /// In en, this message translates to:
  /// **'Could not load free time — {error}'**
  String couldNotLoadFreeTimeError(String error);

  /// No description provided for @familyPulseTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Pulse'**
  String get familyPulseTitle;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hey, {name}'**
  String greeting(String name);

  /// No description provided for @upcomingStat.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingStat;

  /// No description provided for @todaysSchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get todaysSchedule;

  /// No description provided for @nothingToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the calendar today.'**
  String get nothingToday;

  /// No description provided for @comingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get comingUp;

  /// No description provided for @nothingScheduledYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled yet.'**
  String get nothingScheduledYet;

  /// No description provided for @jumpTo.
  ///
  /// In en, this message translates to:
  /// **'Jump to'**
  String get jumpTo;

  /// No description provided for @couldNotLoadPulseError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your pulse: {error}'**
  String couldNotLoadPulseError(String error);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileButton;

  /// No description provided for @yourRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your role in the family'**
  String get yourRoleSubtitle;

  /// No description provided for @yourLabelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your label'**
  String get yourLabelSubtitle;

  /// No description provided for @yourFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your family'**
  String get yourFamilySubtitle;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @couldNotUpdateProfileError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update profile — {error}'**
  String couldNotUpdateProfileError(String error);

  /// No description provided for @changePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhotoLabel;

  /// No description provided for @takePhotoOption.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhotoOption;

  /// No description provided for @chooseFromGalleryOption.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGalleryOption;

  /// No description provided for @removePhotoOption.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhotoOption;

  /// No description provided for @couldNotPickPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the photo picker — {error}'**
  String couldNotPickPhotoError(String error);

  /// No description provided for @ageFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageFieldLabel;

  /// No description provided for @ageInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter an age between 0 and 120'**
  String get ageInvalidError;

  /// No description provided for @genderFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderFieldLabel;

  /// No description provided for @genderNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get genderNotSet;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @genderPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderPreferNotToSay;

  /// No description provided for @yourAgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your age'**
  String get yourAgeSubtitle;

  /// No description provided for @yourGenderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your gender'**
  String get yourGenderSubtitle;

  /// No description provided for @storageErrorCanceled.
  ///
  /// In en, this message translates to:
  /// **'Photo selection was canceled'**
  String get storageErrorCanceled;

  /// No description provided for @storageErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload your photo. Please try again.'**
  String get storageErrorUnknown;

  /// No description provided for @nameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameFieldLabel;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to log back in to see your family\'s calendar.'**
  String get signOutConfirmContent;

  /// No description provided for @couldNotSignOutError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out: {error}'**
  String couldNotSignOutError(String error);

  /// No description provided for @categorySchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get categorySchool;

  /// No description provided for @categoryHobby.
  ///
  /// In en, this message translates to:
  /// **'Hobby'**
  String get categoryHobby;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @roleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get roleParent;

  /// No description provided for @roleChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get roleChild;

  /// No description provided for @roleGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get roleGuardian;

  /// No description provided for @roleOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get roleOther;

  /// No description provided for @myFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Family'**
  String get myFamilyTitle;

  /// No description provided for @familyGroupsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Family groups'**
  String get familyGroupsTooltip;

  /// No description provided for @membersHeader.
  ///
  /// In en, this message translates to:
  /// **'MEMBERS'**
  String get membersHeader;

  /// No description provided for @noMembersFoundYet.
  ///
  /// In en, this message translates to:
  /// **'No members found yet.'**
  String get noMembersFoundYet;

  /// No description provided for @couldNotLoadFamilyInfoError.
  ///
  /// In en, this message translates to:
  /// **'Could not load family info — {error}'**
  String couldNotLoadFamilyInfoError(String error);

  /// No description provided for @couldNotLoadMembersError.
  ///
  /// In en, this message translates to:
  /// **'Could not load members — {error}'**
  String couldNotLoadMembersError(String error);

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String createdOn(String date);

  /// No description provided for @copyFamilyCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy family code'**
  String get copyFamilyCodeTooltip;

  /// No description provided for @familyCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Family code copied'**
  String get familyCodeCopied;

  /// No description provided for @shareCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Share this code so others can join.'**
  String get shareCodeHint;

  /// No description provided for @youBadge.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youBadge;

  /// No description provided for @renameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameTooltip;

  /// No description provided for @renameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename {name}'**
  String renameDialogTitle(String name);

  /// No description provided for @memberUpdated.
  ///
  /// In en, this message translates to:
  /// **'{name} updated'**
  String memberUpdated(String name);

  /// No description provided for @couldNotUpdateMemberError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update member — {error}'**
  String couldNotUpdateMemberError(String error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearanceHeader.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceHeader;

  /// No description provided for @systemOption.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemOption;

  /// No description provided for @lightOption.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightOption;

  /// No description provided for @darkOption.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkOption;

  /// No description provided for @colorThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Color theme'**
  String get colorThemeLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystemOption.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystemOption;

  /// No description provided for @languageEnglishOption.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishOption;

  /// No description provided for @languageFinnishOption.
  ///
  /// In en, this message translates to:
  /// **'Suomi'**
  String get languageFinnishOption;

  /// No description provided for @languageSwedishOption.
  ///
  /// In en, this message translates to:
  /// **'Svenska'**
  String get languageSwedishOption;

  /// No description provided for @yourNameHeader.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameHeader;

  /// No description provided for @addYourName.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get addYourName;

  /// No description provided for @yourFamilyHeader.
  ///
  /// In en, this message translates to:
  /// **'Your family'**
  String get yourFamilyHeader;

  /// No description provided for @familyCodeShareHelper.
  ///
  /// In en, this message translates to:
  /// **'Family code — share so others can join'**
  String get familyCodeShareHelper;

  /// No description provided for @calendarHeader.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarHeader;

  /// No description provided for @showEmptyDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Show empty days by default'**
  String get showEmptyDaysTitle;

  /// No description provided for @showEmptyDaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applies next time you open the calendar — you can still toggle it there for a quick look.'**
  String get showEmptyDaysSubtitle;

  /// No description provided for @accountHeader.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountHeader;

  /// No description provided for @nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get nameUpdated;

  /// No description provided for @couldNotUpdateNameError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update name — {error}'**
  String couldNotUpdateNameError(String error);

  /// No description provided for @familyCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Calendar'**
  String get familyCalendarTitle;

  /// No description provided for @hideEmptyDaysTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide empty days'**
  String get hideEmptyDaysTooltip;

  /// No description provided for @showEmptyDaysTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show empty days'**
  String get showEmptyDaysTooltip;

  /// No description provided for @myFamilyTooltip.
  ///
  /// In en, this message translates to:
  /// **'My family'**
  String get myFamilyTooltip;

  /// No description provided for @couldNotFindFamilyRetryError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your family yet — try again in a moment.'**
  String get couldNotFindFamilyRetryError;

  /// No description provided for @deleteEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get deleteEventTitle;

  /// No description provided for @deleteEventContent.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed for everyone.'**
  String deleteEventContent(String title);

  /// No description provided for @eventDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" deleted'**
  String eventDeleted(String title);

  /// No description provided for @couldNotDeleteEventError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete event — {error}'**
  String couldNotDeleteEventError(String error);

  /// No description provided for @eventAdded.
  ///
  /// In en, this message translates to:
  /// **'Event added'**
  String get eventAdded;

  /// No description provided for @eventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event updated'**
  String get eventUpdated;

  /// No description provided for @addEventTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEventTooltip;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No events yet — add one to plan family time.'**
  String get noEventsYet;

  /// No description provided for @editEventTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get editEventTooltip;

  /// No description provided for @deleteEventTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get deleteEventTooltip;

  /// No description provided for @newEventButton.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get newEventButton;

  /// No description provided for @addEventDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEventDialogTitle;

  /// No description provided for @editEventDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get editEventDialogTitle;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @eventTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String eventTimeLabel(String time);

  /// No description provided for @couldNotSaveEventError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save event — {error}'**
  String couldNotSaveEventError(String error);

  /// No description provided for @eventsForDate.
  ///
  /// In en, this message translates to:
  /// **'Events for {date}'**
  String eventsForDate(String date);

  /// No description provided for @couldNotLoadEventsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load events: {error}'**
  String couldNotLoadEventsError(String error);

  /// No description provided for @openDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openDayLabel;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @noEventsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'No events yet — analytics will fill in as your family starts adding things to the calendar.'**
  String get noEventsAnalytics;

  /// No description provided for @couldNotLoadAnalyticsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load analytics — {error}'**
  String couldNotLoadAnalyticsError(String error);

  /// No description provided for @totalEventsStat.
  ///
  /// In en, this message translates to:
  /// **'Total events'**
  String get totalEventsStat;

  /// No description provided for @familyMembersStat.
  ///
  /// In en, this message translates to:
  /// **'Family members'**
  String get familyMembersStat;

  /// No description provided for @next7DaysStat.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get next7DaysStat;

  /// No description provided for @busiestDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Busiest day of the week'**
  String get busiestDayTitle;

  /// No description provided for @mostActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Who\'s added the most'**
  String get mostActiveTitle;

  /// No description provided for @noEventsLoggedYet.
  ///
  /// In en, this message translates to:
  /// **'No events logged yet.'**
  String get noEventsLoggedYet;

  /// No description provided for @byCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategoryTitle;

  /// No description provided for @unknownContributor.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownContributor;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in to do that.'**
  String get authErrorNotSignedIn;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorUnknown;

  /// No description provided for @familyErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Family not found. Check the code and try again.'**
  String get familyErrorNotFound;

  /// No description provided for @recurrenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get recurrenceLabel;

  /// No description provided for @recurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t repeat'**
  String get recurrenceNone;

  /// No description provided for @recurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrenceYearly;

  /// No description provided for @recurrenceNoEndDate.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get recurrenceNoEndDate;

  /// No description provided for @recurrenceEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String recurrenceEndsOn(String date);

  /// No description provided for @recurrenceClearEndDate.
  ///
  /// In en, this message translates to:
  /// **'Remove end date'**
  String get recurrenceClearEndDate;

  /// No description provided for @partOfRecurringSeriesNote.
  ///
  /// In en, this message translates to:
  /// **'This is one event in a repeating series — editing it only changes this occurrence, not the whole series.'**
  String get partOfRecurringSeriesNote;

  /// No description provided for @reminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderLabel;

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get reminderOff;

  /// No description provided for @reminderAtEventTime.
  ///
  /// In en, this message translates to:
  /// **'At the time of the event'**
  String get reminderAtEventTime;

  /// No description provided for @reminderMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String reminderMinutesBefore(int minutes);

  /// No description provided for @reminderHoursBefore.
  ///
  /// In en, this message translates to:
  /// **'{hours} hour before'**
  String reminderHoursBefore(int hours);

  /// No description provided for @reminderDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'{days} day before'**
  String reminderDaysBefore(int days);

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming: {title}'**
  String reminderNotificationTitle(String title);

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Starts at {time}'**
  String reminderNotificationBody(String time);

  /// No description provided for @weatherHeader.
  ///
  /// In en, this message translates to:
  /// **'Family location'**
  String get weatherHeader;

  /// No description provided for @weatherLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used to show weather on your calendar'**
  String get weatherLocationSubtitle;

  /// No description provided for @weatherNotSetLabel.
  ///
  /// In en, this message translates to:
  /// **'No location set'**
  String get weatherNotSetLabel;

  /// No description provided for @weatherSetLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get weatherSetLocationButton;

  /// No description provided for @weatherChangeLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get weatherChangeLocationTooltip;

  /// No description provided for @weatherClearLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove location'**
  String get weatherClearLocationTooltip;

  /// No description provided for @weatherRemoveLocationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove the family\'s weather location? You can set a new one anytime.'**
  String get weatherRemoveLocationConfirm;

  /// No description provided for @weatherSearchDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Family location'**
  String get weatherSearchDialogTitle;

  /// No description provided for @weatherSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Used to show a 7-day forecast on your calendar so you can plan around the weather.'**
  String get weatherSearchHint;

  /// No description provided for @weatherSearchFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'City or town'**
  String get weatherSearchFieldLabel;

  /// No description provided for @weatherSearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get weatherSearchButton;

  /// No description provided for @weatherSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching places found'**
  String get weatherSearchNoResults;

  /// No description provided for @weatherSearchFailedError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search locations — check your connection and try again'**
  String get weatherSearchFailedError;

  /// No description provided for @weatherLocationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location saved'**
  String get weatherLocationSaved;

  /// No description provided for @weatherLocationRemoved.
  ///
  /// In en, this message translates to:
  /// **'Location removed'**
  String get weatherLocationRemoved;

  /// No description provided for @couldNotUpdateLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not update location: {error}'**
  String couldNotUpdateLocationError(String error);

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherOvercast.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get weatherOvercast;

  /// No description provided for @weatherFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherFog;

  /// No description provided for @weatherDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunderstorm;

  /// No description provided for @weatherDaySummary.
  ///
  /// In en, this message translates to:
  /// **'{description} · {tempMax}°/{tempMin}°C · {rainChance}% rain'**
  String weatherDaySummary(
    String description,
    int tempMax,
    int tempMin,
    int rainChance,
  );

  /// No description provided for @rainRiskTooltip.
  ///
  /// In en, this message translates to:
  /// **'{percent}% chance of rain'**
  String rainRiskTooltip(int percent);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fi', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fi':
      return AppLocalizationsFi();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
