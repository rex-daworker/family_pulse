// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get cancel => 'Avbryt';

  @override
  String get save => 'Spara';

  @override
  String get delete => 'Ta bort';

  @override
  String get signOut => 'Logga ut';

  @override
  String get notesLabel => 'Anteckningar';

  @override
  String get titleFieldLabel => 'Titel';

  @override
  String get titleRequiredError => 'Titel krävs';

  @override
  String get nameRequiredError => 'Namn krävs';

  @override
  String get labelOptional => 'Etikett (valfritt)';

  @override
  String get labelHint =>
      't.ex. Mamma, Pappa — hjälper till att skilja föräldrar åt';

  @override
  String get labelHintGeneric => 't.ex. Mamma, Pappa, Mormor';

  @override
  String get yourNameLabel => 'Ditt namn';

  @override
  String get emailLabel => 'E-post';

  @override
  String get passwordLabel => 'Lösenord';

  @override
  String get emailRequiredError => 'E-post krävs';

  @override
  String get emailInvalidError => 'Ange en giltig e-postadress';

  @override
  String get passwordRequiredError => 'Lösenord krävs';

  @override
  String get showPassword => 'Visa lösenord';

  @override
  String get hidePassword => 'Dölj lösenord';

  @override
  String get notInFamilyYet => 'Du tillhör inte en familj ännu.';

  @override
  String get familyMemberFallback => 'Familjemedlem';

  @override
  String get codeCopied => 'Koden kopierad';

  @override
  String get copyCodeTooltip => 'Kopiera kod';

  @override
  String get todayLabel => 'Idag';

  @override
  String get homeNav => 'Hem';

  @override
  String get calendarNav => 'Kalender';

  @override
  String get familyNav => 'Familj';

  @override
  String get freeTimeNav => 'Ledig tid';

  @override
  String get groupsNav => 'Grupper';

  @override
  String get analyticsNav => 'Statistik';

  @override
  String get profileNav => 'Profil';

  @override
  String get settingsNav => 'Inställningar';

  @override
  String get loginTitle => 'FamilyPulse-inloggning';

  @override
  String get loginButton => 'Logga in';

  @override
  String get loginRegisterPrompt => 'Har du inget konto? Registrera dig här.';

  @override
  String get registerTitle => 'Skapa konto';

  @override
  String get fullNameLabel => 'Fullständigt namn';

  @override
  String get confirmEmailLabel => 'Bekräfta e-post';

  @override
  String get confirmEmailRequiredError => 'Bekräfta din e-postadress';

  @override
  String get emailsDontMatchError => 'E-postadresserna matchar inte';

  @override
  String get confirmPasswordLabel => 'Bekräfta lösenord';

  @override
  String get confirmPasswordRequiredError => 'Bekräfta ditt lösenord';

  @override
  String get passwordTooShortError => 'Minst 6 tecken';

  @override
  String get passwordsDontMatchError => 'Lösenorden matchar inte';

  @override
  String get signUpButton => 'Registrera dig';

  @override
  String get loginPrompt => 'Har du redan ett konto? Logga in.';

  @override
  String get welcomeTagline => 'Familjelivet saknar inte ännu en gruppchatt.';

  @override
  String get welcomePitch =>
      'Det som saknas är en puls. FamilyPulse förvandlar spridda sms, glömda hämtningar och \"vänta — vem är ledig på lördag?\" till ett gemensamt flöde: en levande kalender, en puls i realtid av allas dag och noll dubbelbokade fotbollsträningar.';

  @override
  String get createAccountButton => 'Skapa konto';

  @override
  String get logInButton => 'Logga in';

  @override
  String get familyChoiceTitle => 'Välkommen';

  @override
  String get createFamilyButton => 'Skapa en familj';

  @override
  String get joinFamilyButton => 'Gå med i en familj';

  @override
  String get joinFamilyTitle => 'Gå med i en familj';

  @override
  String get familyCodeLabel => 'Familjekod';

  @override
  String get familyCodeHelper => 'Be en familjemedlem om familjens kod.';

  @override
  String get roleLabel => 'Roll';

  @override
  String get fillBothFieldsError => 'Fyll i båda fälten.';

  @override
  String get joinFamilyAction => 'Gå med i familj';

  @override
  String get createFamilyTitle => 'Skapa en familj';

  @override
  String get familyNameLabel => 'Familjens namn';

  @override
  String get familyCreatedTitle => 'Familj skapad';

  @override
  String shareCodeMessage(String familyId) {
    return 'Dela den här koden så att andra kan gå med:\n\n$familyId';
  }

  @override
  String get continueButton => 'Fortsätt';

  @override
  String get createFamilyAction => 'Skapa familj';

  @override
  String get familyGroupsTitle => 'Familjegrupper';

  @override
  String couldNotLoadGroupsError(String error) {
    return 'Kunde inte läsa in grupper — $error';
  }

  @override
  String get unknownMember => 'Okänd medlem';

  @override
  String get noGroupsYet =>
      'Inga grupper ännu. Skapa en för saker som \"Barnen\" eller \"Hushållssysslor\" för att organisera vem som är involverad i vad.';

  @override
  String get newGroup => 'Ny grupp';

  @override
  String get editGroup => 'Redigera grupp';

  @override
  String get deleteGroupTooltip => 'Ta bort grupp';

  @override
  String get deleteGroupTitle => 'Ta bort grupp?';

  @override
  String deleteGroupContent(String name) {
    return '\"$name\" tas bort för alla.';
  }

  @override
  String couldNotDeleteGroupError(String error) {
    return 'Kunde inte ta bort gruppen — $error';
  }

  @override
  String get noMembersYetGroup => 'Inga medlemmar ännu.';

  @override
  String get groupNameLabel => 'Gruppnamn';

  @override
  String get groupNameRequiredError => 'Gruppnamn krävs';

  @override
  String get membersLabel => 'Medlemmar';

  @override
  String get noFamilyMembersFoundYet => 'Inga familjemedlemmar hittades ännu.';

  @override
  String couldNotSaveGroupError(String error) {
    return 'Kunde inte spara gruppen — $error';
  }

  @override
  String get freeTimeTitle => 'Ledig tid';

  @override
  String get previousDayTooltip => 'Föregående dag';

  @override
  String get nextDayTooltip => 'Nästa dag';

  @override
  String get minDuration30 => '30 min+';

  @override
  String get minDuration60 => '1 tim+';

  @override
  String get minDuration120 => '2 tim+';

  @override
  String get couldNotFindMembers => 'Kunde inte hitta några familjemedlemmar.';

  @override
  String get noFreeWindow =>
      'Inget så långt gemensamt ledigt tidsfönster mellan kl. 7 och 21 den här dagen. Prova en kortare minsta tid eller en annan dag.';

  @override
  String freeForEveryone(int duration) {
    return '$duration minuter, ledigt för alla';
  }

  @override
  String get scheduleButton => 'Boka';

  @override
  String scheduleAtTitle(String time) {
    return 'Boka kl. $time';
  }

  @override
  String couldNotCreateEventError(String error) {
    return 'Kunde inte skapa händelsen — $error';
  }

  @override
  String couldNotLoadFamilyMembersError(String error) {
    return 'Kunde inte läsa in familjemedlemmar — $error';
  }

  @override
  String couldNotLoadYourFamilyError(String error) {
    return 'Kunde inte läsa in din familj — $error';
  }

  @override
  String couldNotLoadFreeTimeError(String error) {
    return 'Kunde inte läsa in ledig tid — $error';
  }

  @override
  String get familyPulseTitle => 'Family Pulse';

  @override
  String greeting(String name) {
    return 'Hej, $name';
  }

  @override
  String get upcomingStat => 'Kommande';

  @override
  String get todaysSchedule => 'Dagens schema';

  @override
  String get nothingToday => 'Inget i kalendern idag.';

  @override
  String get comingUp => 'Kommande';

  @override
  String get nothingScheduledYet => 'Inget inplanerat än.';

  @override
  String get jumpTo => 'Hoppa till';

  @override
  String couldNotLoadPulseError(String error) {
    return 'Kunde inte läsa in din puls: $error';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get editProfileButton => 'Redigera profil';

  @override
  String get yourRoleSubtitle => 'Din roll i familjen';

  @override
  String get yourLabelSubtitle => 'Din etikett';

  @override
  String get yourFamilySubtitle => 'Din familj';

  @override
  String get profileUpdated => 'Profilen uppdaterad';

  @override
  String couldNotUpdateProfileError(String error) {
    return 'Kunde inte uppdatera profilen — $error';
  }

  @override
  String get changePhotoLabel => 'Byt foto';

  @override
  String get takePhotoOption => 'Ta foto';

  @override
  String get chooseFromGalleryOption => 'Välj från galleriet';

  @override
  String get removePhotoOption => 'Ta bort foto';

  @override
  String couldNotPickPhotoError(String error) {
    return 'Kunde inte öppna fotoväljaren — $error';
  }

  @override
  String get ageFieldLabel => 'Ålder';

  @override
  String get ageInvalidError => 'Ange en ålder mellan 0 och 120';

  @override
  String get genderFieldLabel => 'Kön';

  @override
  String get genderNotSet => 'Inte angivet';

  @override
  String get genderFemale => 'Kvinna';

  @override
  String get genderMale => 'Man';

  @override
  String get genderOther => 'Annat';

  @override
  String get genderPreferNotToSay => 'Vill inte ange';

  @override
  String get yourAgeSubtitle => 'Din ålder';

  @override
  String get yourGenderSubtitle => 'Ditt kön';

  @override
  String get storageErrorCanceled => 'Fotovalet avbröts';

  @override
  String get storageErrorUnknown => 'Kunde inte ladda upp fotot. Försök igen.';

  @override
  String get nameFieldLabel => 'Namn';

  @override
  String get signOutConfirmTitle => 'Logga ut?';

  @override
  String get signOutConfirmContent =>
      'Du behöver logga in igen för att se din familjs kalender.';

  @override
  String couldNotSignOutError(String error) {
    return 'Kunde inte logga ut: $error';
  }

  @override
  String get categorySchool => 'Skola';

  @override
  String get categoryHobby => 'Hobby';

  @override
  String get categoryWork => 'Arbete';

  @override
  String get categoryOther => 'Övrigt';

  @override
  String get roleParent => 'Förälder';

  @override
  String get roleChild => 'Barn';

  @override
  String get roleGuardian => 'Vårdnadshavare';

  @override
  String get roleOther => 'Övrig';

  @override
  String get myFamilyTitle => 'Min familj';

  @override
  String get familyGroupsTooltip => 'Familjegrupper';

  @override
  String get membersHeader => 'MEDLEMMAR';

  @override
  String get noMembersFoundYet => 'Inga medlemmar hittades ännu.';

  @override
  String couldNotLoadFamilyInfoError(String error) {
    return 'Kunde inte läsa in familjeinformation — $error';
  }

  @override
  String couldNotLoadMembersError(String error) {
    return 'Kunde inte läsa in medlemmar — $error';
  }

  @override
  String createdOn(String date) {
    return 'Skapad $date';
  }

  @override
  String get copyFamilyCodeTooltip => 'Kopiera familjekod';

  @override
  String get familyCodeCopied => 'Familjekoden kopierad';

  @override
  String get shareCodeHint => 'Dela den här koden så att andra kan gå med.';

  @override
  String get youBadge => 'Du';

  @override
  String get renameTooltip => 'Byt namn';

  @override
  String renameDialogTitle(String name) {
    return 'Byt namn på $name';
  }

  @override
  String memberUpdated(String name) {
    return '$name uppdaterad';
  }

  @override
  String couldNotUpdateMemberError(String error) {
    return 'Kunde inte uppdatera medlemmen — $error';
  }

  @override
  String get settingsTitle => 'Inställningar';

  @override
  String get appearanceHeader => 'Utseende';

  @override
  String get systemOption => 'System';

  @override
  String get lightOption => 'Ljust';

  @override
  String get darkOption => 'Mörkt';

  @override
  String get colorThemeLabel => 'Färgtema';

  @override
  String get languageLabel => 'Språk';

  @override
  String get languageSystemOption => 'System';

  @override
  String get languageEnglishOption => 'English';

  @override
  String get languageFinnishOption => 'Suomi';

  @override
  String get languageSwedishOption => 'Svenska';

  @override
  String get yourNameHeader => 'Ditt namn';

  @override
  String get addYourName => 'Lägg till ditt namn';

  @override
  String get yourFamilyHeader => 'Din familj';

  @override
  String get familyCodeShareHelper =>
      'Familjekod — dela så att andra kan gå med';

  @override
  String get calendarHeader => 'Kalender';

  @override
  String get showEmptyDaysTitle => 'Visa tomma dagar som standard';

  @override
  String get showEmptyDaysSubtitle =>
      'Gäller nästa gång du öppnar kalendern — du kan fortfarande växla det där för en snabb titt.';

  @override
  String get accountHeader => 'Konto';

  @override
  String get nameUpdated => 'Namnet uppdaterat';

  @override
  String couldNotUpdateNameError(String error) {
    return 'Kunde inte uppdatera namnet — $error';
  }

  @override
  String get familyCalendarTitle => 'Familjekalender';

  @override
  String get hideEmptyDaysTooltip => 'Dölj tomma dagar';

  @override
  String get showEmptyDaysTooltip => 'Visa tomma dagar';

  @override
  String get myFamilyTooltip => 'Min familj';

  @override
  String get couldNotFindFamilyRetryError =>
      'Kunde inte hitta din familj ännu — försök igen om en stund.';

  @override
  String get deleteEventTitle => 'Ta bort händelse?';

  @override
  String deleteEventContent(String title) {
    return '\"$title\" tas bort för alla.';
  }

  @override
  String eventDeleted(String title) {
    return '\"$title\" borttagen';
  }

  @override
  String couldNotDeleteEventError(String error) {
    return 'Kunde inte ta bort händelsen — $error';
  }

  @override
  String get eventAdded => 'Händelse tillagd';

  @override
  String get eventUpdated => 'Händelse uppdaterad';

  @override
  String get addEventTooltip => 'Lägg till händelse';

  @override
  String get noEventsYet =>
      'Inga händelser ännu — lägg till en för att planera familjetid.';

  @override
  String get editEventTooltip => 'Redigera händelse';

  @override
  String get deleteEventTooltip => 'Ta bort händelse';

  @override
  String get newEventButton => 'Ny händelse';

  @override
  String get addEventDialogTitle => 'Lägg till händelse';

  @override
  String get editEventDialogTitle => 'Redigera händelse';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String eventTimeLabel(String time) {
    return 'Tid: $time';
  }

  @override
  String couldNotSaveEventError(String error) {
    return 'Kunde inte spara händelsen — $error';
  }

  @override
  String eventsForDate(String date) {
    return 'Händelser för $date';
  }

  @override
  String couldNotLoadEventsError(String error) {
    return 'Kunde inte läsa in händelser: $error';
  }

  @override
  String get openDayLabel => 'Ledig';

  @override
  String get analyticsTitle => 'Statistik';

  @override
  String get noEventsAnalytics =>
      'Inga händelser ännu — statistiken fylls i allt eftersom din familj lägger till saker i kalendern.';

  @override
  String couldNotLoadAnalyticsError(String error) {
    return 'Kunde inte läsa in statistik — $error';
  }

  @override
  String get totalEventsStat => 'Totalt antal händelser';

  @override
  String get familyMembersStat => 'Familjemedlemmar';

  @override
  String get next7DaysStat => 'Nästa 7 dagar';

  @override
  String get busiestDayTitle => 'Veckans mest aktiva dag';

  @override
  String get mostActiveTitle => 'Vem har lagt till mest';

  @override
  String get noEventsLoggedYet => 'Inga händelser registrerade ännu.';

  @override
  String get byCategoryTitle => 'Efter kategori';

  @override
  String get unknownContributor => 'Okänd';

  @override
  String get authErrorWeakPassword =>
      'Lösenordet är för svagt. Använd minst 6 tecken.';

  @override
  String get authErrorEmailInUse =>
      'Det finns redan ett konto med den här e-postadressen.';

  @override
  String get authErrorUserNotFound =>
      'Inget konto hittades med den här e-postadressen.';

  @override
  String get authErrorWrongPassword => 'Fel lösenord. Försök igen.';

  @override
  String get authErrorInvalidEmail => 'Ange en giltig e-postadress.';

  @override
  String get authErrorNotSignedIn => 'Du måste vara inloggad för att göra det.';

  @override
  String get authErrorUnknown => 'Något gick fel. Försök igen.';

  @override
  String get familyErrorNotFound =>
      'Familjen hittades inte. Kontrollera koden och försök igen.';
}
