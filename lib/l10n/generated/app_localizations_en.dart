// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get signOut => 'Sign out';

  @override
  String get notesLabel => 'Notes';

  @override
  String get titleFieldLabel => 'Title';

  @override
  String get titleRequiredError => 'Title is required';

  @override
  String get nameRequiredError => 'Name is required';

  @override
  String get labelOptional => 'Label (optional)';

  @override
  String get labelHint => 'e.g. Mom, Dad — helps tell parents apart';

  @override
  String get labelHintGeneric => 'e.g. Mom, Dad, Grandma';

  @override
  String get yourNameLabel => 'Your name';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailRequiredError => 'Email is required';

  @override
  String get emailInvalidError => 'Enter a valid email address';

  @override
  String get passwordRequiredError => 'Password is required';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get notInFamilyYet => 'You\'re not part of a family yet.';

  @override
  String get familyMemberFallback => 'Family member';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get copyCodeTooltip => 'Copy code';

  @override
  String get todayLabel => 'Today';

  @override
  String get homeNav => 'Home';

  @override
  String get calendarNav => 'Calendar';

  @override
  String get familyNav => 'Family';

  @override
  String get freeTimeNav => 'Free time';

  @override
  String get groupsNav => 'Groups';

  @override
  String get analyticsNav => 'Analytics';

  @override
  String get profileNav => 'Profile';

  @override
  String get settingsNav => 'Settings';

  @override
  String get loginTitle => 'FamilyPulse Login';

  @override
  String get loginButton => 'Login';

  @override
  String get loginRegisterPrompt => 'Don\'t have an account? Register here.';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get confirmEmailLabel => 'Confirm email';

  @override
  String get confirmEmailRequiredError => 'Please confirm your email';

  @override
  String get emailsDontMatchError => 'Emails don\'t match';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordRequiredError => 'Please confirm your password';

  @override
  String get passwordTooShortError => 'At least 6 characters';

  @override
  String get passwordsDontMatchError => 'Passwords don\'t match';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get loginPrompt => 'Already have an account? Log in.';

  @override
  String get welcomeTagline => 'Family life isn\'t missing another group chat.';

  @override
  String get welcomePitch =>
      'It\'s missing a heartbeat. FamilyPulse turns scattered texts, forgotten pickups, and \"wait — who\'s free Saturday?\" into one shared rhythm: a live calendar, a real-time pulse of everyone\'s day, and zero double-booked soccer practice.';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get logInButton => 'Log in';

  @override
  String get familyChoiceTitle => 'Welcome';

  @override
  String get createFamilyButton => 'Create a family';

  @override
  String get joinFamilyButton => 'Join a family';

  @override
  String get joinFamilyTitle => 'Join a family';

  @override
  String get familyCodeLabel => 'Family code';

  @override
  String get familyCodeHelper => 'Ask a family member for their family code.';

  @override
  String get roleLabel => 'Role';

  @override
  String get fillBothFieldsError => 'Please fill in both fields.';

  @override
  String get joinFamilyAction => 'Join family';

  @override
  String get createFamilyTitle => 'Create a family';

  @override
  String get familyNameLabel => 'Family name';

  @override
  String get familyCreatedTitle => 'Family created';

  @override
  String shareCodeMessage(String familyId) {
    return 'Share this code so others can join:\n\n$familyId';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get createFamilyAction => 'Create family';

  @override
  String get familyGroupsTitle => 'Family Groups';

  @override
  String couldNotLoadGroupsError(String error) {
    return 'Could not load groups — $error';
  }

  @override
  String get unknownMember => 'Unknown member';

  @override
  String get noGroupsYet =>
      'No groups yet. Make one for things like \"Kids\" or \"Chores squad\" to organize who\'s involved in what.';

  @override
  String get newGroup => 'New group';

  @override
  String get editGroup => 'Edit group';

  @override
  String get deleteGroupTooltip => 'Delete group';

  @override
  String get deleteGroupTitle => 'Delete group?';

  @override
  String deleteGroupContent(String name) {
    return '\"$name\" will be removed for everyone.';
  }

  @override
  String couldNotDeleteGroupError(String error) {
    return 'Couldn\'t delete group — $error';
  }

  @override
  String get noMembersYetGroup => 'No members yet.';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupNameRequiredError => 'Group name is required';

  @override
  String get membersLabel => 'Members';

  @override
  String get noFamilyMembersFoundYet => 'No family members found yet.';

  @override
  String couldNotSaveGroupError(String error) {
    return 'Couldn\'t save group — $error';
  }

  @override
  String get freeTimeTitle => 'Free Time';

  @override
  String get previousDayTooltip => 'Previous day';

  @override
  String get nextDayTooltip => 'Next day';

  @override
  String get minDuration30 => '30 min+';

  @override
  String get minDuration60 => '1 hr+';

  @override
  String get minDuration120 => '2 hr+';

  @override
  String get couldNotFindMembers => 'Could not find any family members.';

  @override
  String get noFreeWindow =>
      'No window that long, free for everyone, between 7 AM and 9 PM on this day. Try a shorter minimum or another day.';

  @override
  String freeForEveryone(int duration) {
    return '$duration minutes, free for everyone';
  }

  @override
  String get scheduleButton => 'Schedule';

  @override
  String scheduleAtTitle(String time) {
    return 'Schedule at $time';
  }

  @override
  String get freeTimeRetryButton => 'Try again';

  @override
  String freeSlotsFoundCount(int count) {
    return '$count free periods found';
  }

  @override
  String couldNotCreateEventError(String error) {
    return 'Couldn\'t create event — $error';
  }

  @override
  String couldNotLoadFamilyMembersError(String error) {
    return 'Could not load family members — $error';
  }

  @override
  String couldNotLoadYourFamilyError(String error) {
    return 'Could not load your family — $error';
  }

  @override
  String couldNotLoadFreeTimeError(String error) {
    return 'Could not load free time — $error';
  }

  @override
  String get familyPulseTitle => 'Family Pulse';

  @override
  String greeting(String name) {
    return 'Hey, $name';
  }

  @override
  String get upcomingStat => 'Upcoming';

  @override
  String get todaysSchedule => 'Today\'s schedule';

  @override
  String get nothingToday => 'Nothing on the calendar today.';

  @override
  String get comingUp => 'Coming up';

  @override
  String get nothingScheduledYet => 'Nothing scheduled yet.';

  @override
  String get jumpTo => 'Jump to';

  @override
  String couldNotLoadPulseError(String error) {
    return 'Could not load your pulse: $error';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get editProfileButton => 'Edit profile';

  @override
  String get yourRoleSubtitle => 'Your role in the family';

  @override
  String get yourLabelSubtitle => 'Your label';

  @override
  String get yourFamilySubtitle => 'Your family';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String couldNotUpdateProfileError(String error) {
    return 'Couldn\'t update profile — $error';
  }

  @override
  String get changePhotoLabel => 'Change photo';

  @override
  String get takePhotoOption => 'Take photo';

  @override
  String get chooseFromGalleryOption => 'Choose from gallery';

  @override
  String get removePhotoOption => 'Remove photo';

  @override
  String couldNotPickPhotoError(String error) {
    return 'Couldn\'t open the photo picker — $error';
  }

  @override
  String get ageFieldLabel => 'Age';

  @override
  String get ageInvalidError => 'Enter an age between 0 and 120';

  @override
  String get genderFieldLabel => 'Gender';

  @override
  String get genderNotSet => 'Not set';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMale => 'Male';

  @override
  String get genderOther => 'Other';

  @override
  String get genderPreferNotToSay => 'Prefer not to say';

  @override
  String get yourAgeSubtitle => 'Your age';

  @override
  String get yourGenderSubtitle => 'Your gender';

  @override
  String get storageErrorCanceled => 'Photo selection was canceled';

  @override
  String get storageErrorUnknown =>
      'Couldn\'t upload your photo. Please try again.';

  @override
  String get nameFieldLabel => 'Name';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmContent =>
      'You\'ll need to log back in to see your family\'s calendar.';

  @override
  String couldNotSignOutError(String error) {
    return 'Could not sign out: $error';
  }

  @override
  String get categorySchool => 'School';

  @override
  String get categoryHobby => 'Hobby';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryOther => 'Other';

  @override
  String get roleParent => 'Parent';

  @override
  String get roleChild => 'Child';

  @override
  String get roleGuardian => 'Guardian';

  @override
  String get roleOther => 'Other';

  @override
  String get myFamilyTitle => 'My Family';

  @override
  String get familyGroupsTooltip => 'Family groups';

  @override
  String get membersHeader => 'MEMBERS';

  @override
  String get noMembersFoundYet => 'No members found yet.';

  @override
  String couldNotLoadFamilyInfoError(String error) {
    return 'Could not load family info — $error';
  }

  @override
  String couldNotLoadMembersError(String error) {
    return 'Could not load members — $error';
  }

  @override
  String createdOn(String date) {
    return 'Created $date';
  }

  @override
  String get copyFamilyCodeTooltip => 'Copy family code';

  @override
  String get familyCodeCopied => 'Family code copied';

  @override
  String get shareCodeHint => 'Share this code so others can join.';

  @override
  String get youBadge => 'You';

  @override
  String get renameTooltip => 'Rename';

  @override
  String renameDialogTitle(String name) {
    return 'Rename $name';
  }

  @override
  String memberUpdated(String name) {
    return '$name updated';
  }

  @override
  String couldNotUpdateMemberError(String error) {
    return 'Couldn\'t update member — $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceHeader => 'Appearance';

  @override
  String get systemOption => 'System';

  @override
  String get lightOption => 'Light';

  @override
  String get darkOption => 'Dark';

  @override
  String get colorThemeLabel => 'Color theme';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystemOption => 'System';

  @override
  String get languageEnglishOption => 'English';

  @override
  String get languageFinnishOption => 'Suomi';

  @override
  String get languageSwedishOption => 'Svenska';

  @override
  String get yourNameHeader => 'Your name';

  @override
  String get addYourName => 'Add your name';

  @override
  String get yourFamilyHeader => 'Your family';

  @override
  String get familyCodeShareHelper => 'Family code — share so others can join';

  @override
  String get calendarHeader => 'Calendar';

  @override
  String get showEmptyDaysTitle => 'Show empty days by default';

  @override
  String get showEmptyDaysSubtitle =>
      'Applies next time you open the calendar — you can still toggle it there for a quick look.';

  @override
  String get accountHeader => 'Account';

  @override
  String get nameUpdated => 'Name updated';

  @override
  String couldNotUpdateNameError(String error) {
    return 'Couldn\'t update name — $error';
  }

  @override
  String get familyCalendarTitle => 'Family Calendar';

  @override
  String get hideEmptyDaysTooltip => 'Hide empty days';

  @override
  String get showEmptyDaysTooltip => 'Show empty days';

  @override
  String get myFamilyTooltip => 'My family';

  @override
  String get couldNotFindFamilyRetryError =>
      'Couldn\'t find your family yet — try again in a moment.';

  @override
  String get deleteEventTitle => 'Delete event?';

  @override
  String deleteEventContent(String title) {
    return '\"$title\" will be removed for everyone.';
  }

  @override
  String eventDeleted(String title) {
    return '\"$title\" deleted';
  }

  @override
  String couldNotDeleteEventError(String error) {
    return 'Couldn\'t delete event — $error';
  }

  @override
  String get eventAdded => 'Event added';

  @override
  String get eventUpdated => 'Event updated';

  @override
  String get addEventTooltip => 'Add event';

  @override
  String get noEventsYet => 'No events yet — add one to plan family time.';

  @override
  String get editEventTooltip => 'Edit event';

  @override
  String get deleteEventTooltip => 'Delete event';

  @override
  String get newEventButton => 'New event';

  @override
  String get addEventDialogTitle => 'Add event';

  @override
  String get editEventDialogTitle => 'Edit event';

  @override
  String get categoryLabel => 'Category';

  @override
  String eventTimeLabel(String time) {
    return 'Time: $time';
  }

  @override
  String couldNotSaveEventError(String error) {
    return 'Couldn\'t save event — $error';
  }

  @override
  String eventsForDate(String date) {
    return 'Events for $date';
  }

  @override
  String couldNotLoadEventsError(String error) {
    return 'Could not load events: $error';
  }

  @override
  String get openDayLabel => 'Open';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get noEventsAnalytics =>
      'No events yet — analytics will fill in as your family starts adding things to the calendar.';

  @override
  String couldNotLoadAnalyticsError(String error) {
    return 'Could not load analytics — $error';
  }

  @override
  String get totalEventsStat => 'Total events';

  @override
  String get familyMembersStat => 'Family members';

  @override
  String get next7DaysStat => 'Next 7 days';

  @override
  String get busiestDayTitle => 'Busiest day of the week';

  @override
  String get mostActiveTitle => 'Who\'s added the most';

  @override
  String get noEventsLoggedYet => 'No events logged yet.';

  @override
  String get byCategoryTitle => 'By category';

  @override
  String get unknownContributor => 'Unknown';

  @override
  String get authErrorWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get authErrorEmailInUse =>
      'An account already exists with this email.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get authErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authErrorNotSignedIn => 'You need to be signed in to do that.';

  @override
  String get authErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get familyErrorNotFound =>
      'Family not found. Check the code and try again.';

  @override
  String get recurrenceLabel => 'Repeats';

  @override
  String get recurrenceNone => 'Doesn\'t repeat';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get recurrenceNoEndDate => 'No end date';

  @override
  String recurrenceEndsOn(String date) {
    return 'Ends $date';
  }

  @override
  String get recurrenceClearEndDate => 'Remove end date';

  @override
  String get partOfRecurringSeriesNote =>
      'This is one event in a repeating series — editing it only changes this occurrence, not the whole series.';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get reminderOff => 'No reminder';

  @override
  String get reminderAtEventTime => 'At the time of the event';

  @override
  String reminderMinutesBefore(int minutes) {
    return '$minutes minutes before';
  }

  @override
  String reminderHoursBefore(int hours) {
    return '$hours hour before';
  }

  @override
  String reminderDaysBefore(int days) {
    return '$days day before';
  }

  @override
  String reminderNotificationTitle(String title) {
    return 'Upcoming: $title';
  }

  @override
  String reminderNotificationBody(String time) {
    return 'Starts at $time';
  }
}
