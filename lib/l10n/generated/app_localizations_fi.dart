// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get cancel => 'Peruuta';

  @override
  String get save => 'Tallenna';

  @override
  String get delete => 'Poista';

  @override
  String get signOut => 'Kirjaudu ulos';

  @override
  String get notesLabel => 'Muistiinpanot';

  @override
  String get titleFieldLabel => 'Otsikko';

  @override
  String get titleRequiredError => 'Otsikko vaaditaan';

  @override
  String get nameRequiredError => 'Nimi vaaditaan';

  @override
  String get labelOptional => 'Nimike (valinnainen)';

  @override
  String get labelHint =>
      'esim. Äiti, Isä — auttaa erottamaan vanhemmat toisistaan';

  @override
  String get labelHintGeneric => 'esim. Äiti, Isä, Mummi';

  @override
  String get yourNameLabel => 'Nimesi';

  @override
  String get emailLabel => 'Sähköposti';

  @override
  String get passwordLabel => 'Salasana';

  @override
  String get emailRequiredError => 'Sähköposti vaaditaan';

  @override
  String get emailInvalidError => 'Anna kelvollinen sähköpostiosoite';

  @override
  String get passwordRequiredError => 'Salasana vaaditaan';

  @override
  String get showPassword => 'Näytä salasana';

  @override
  String get hidePassword => 'Piilota salasana';

  @override
  String get notInFamilyYet => 'Et vielä kuulu perheeseen.';

  @override
  String get familyMemberFallback => 'Perheenjäsen';

  @override
  String get codeCopied => 'Koodi kopioitu';

  @override
  String get copyCodeTooltip => 'Kopioi koodi';

  @override
  String get todayLabel => 'Tänään';

  @override
  String get homeNav => 'Koti';

  @override
  String get calendarNav => 'Kalenteri';

  @override
  String get familyNav => 'Perhe';

  @override
  String get freeTimeNav => 'Vapaa-aika';

  @override
  String get groupsNav => 'Ryhmät';

  @override
  String get analyticsNav => 'Tilastot';

  @override
  String get profileNav => 'Profiili';

  @override
  String get settingsNav => 'Asetukset';

  @override
  String get loginTitle => 'FamilyPulse-kirjautuminen';

  @override
  String get loginButton => 'Kirjaudu';

  @override
  String get loginRegisterPrompt =>
      'Eikö sinulla ole tiliä? Rekisteröidy tästä.';

  @override
  String get registerTitle => 'Luo tili';

  @override
  String get fullNameLabel => 'Koko nimi';

  @override
  String get confirmEmailLabel => 'Vahvista sähköposti';

  @override
  String get confirmEmailRequiredError => 'Vahvista sähköpostiosoitteesi';

  @override
  String get emailsDontMatchError => 'Sähköpostiosoitteet eivät täsmää';

  @override
  String get confirmPasswordLabel => 'Vahvista salasana';

  @override
  String get confirmPasswordRequiredError => 'Vahvista salasanasi';

  @override
  String get passwordTooShortError => 'Vähintään 6 merkkiä';

  @override
  String get passwordsDontMatchError => 'Salasanat eivät täsmää';

  @override
  String get signUpButton => 'Rekisteröidy';

  @override
  String get loginPrompt => 'Onko sinulla jo tili? Kirjaudu sisään.';

  @override
  String get welcomeTagline =>
      'Perhe-elämältä ei puutu vielä yksi ryhmäviesti.';

  @override
  String get welcomePitch =>
      'Siltä puuttuu syke. FamilyPulse muuttaa hajanaiset viestit, unohtuneet hakemiset ja \"hetkinen — kuka on vapaana lauantaina?\" yhdeksi yhteiseksi rytmiksi: reaaliaikaisen kalenterin, jokaisen päivän elävän sykkeen ja nolla päällekkäistä jalkapalloharjoitusta.';

  @override
  String get createAccountButton => 'Luo tili';

  @override
  String get logInButton => 'Kirjaudu sisään';

  @override
  String get familyChoiceTitle => 'Tervetuloa';

  @override
  String get createFamilyButton => 'Luo perhe';

  @override
  String get joinFamilyButton => 'Liity perheeseen';

  @override
  String get joinFamilyTitle => 'Liity perheeseen';

  @override
  String get familyCodeLabel => 'Perhekoodi';

  @override
  String get familyCodeHelper => 'Kysy perhekoodia toiselta perheenjäseneltä.';

  @override
  String get roleLabel => 'Rooli';

  @override
  String get fillBothFieldsError => 'Täytä molemmat kentät.';

  @override
  String get joinFamilyAction => 'Liity perheeseen';

  @override
  String get createFamilyTitle => 'Luo perhe';

  @override
  String get familyNameLabel => 'Perheen nimi';

  @override
  String get familyCreatedTitle => 'Perhe luotu';

  @override
  String shareCodeMessage(String familyId) {
    return 'Jaa tämä koodi, jotta muut voivat liittyä:\n\n$familyId';
  }

  @override
  String get continueButton => 'Jatka';

  @override
  String get createFamilyAction => 'Luo perhe';

  @override
  String get familyGroupsTitle => 'Perheryhmät';

  @override
  String couldNotLoadGroupsError(String error) {
    return 'Ryhmiä ei voitu ladata — $error';
  }

  @override
  String get unknownMember => 'Tuntematon jäsen';

  @override
  String get noGroupsYet =>
      'Ei vielä ryhmiä. Luo esimerkiksi \"Lapset\" tai \"Kotityöt\", jotta näet kuka liittyy mihinkin.';

  @override
  String get newGroup => 'Uusi ryhmä';

  @override
  String get editGroup => 'Muokkaa ryhmää';

  @override
  String get deleteGroupTooltip => 'Poista ryhmä';

  @override
  String get deleteGroupTitle => 'Poistetaanko ryhmä?';

  @override
  String deleteGroupContent(String name) {
    return '\"$name\" poistetaan kaikilta.';
  }

  @override
  String couldNotDeleteGroupError(String error) {
    return 'Ryhmää ei voitu poistaa — $error';
  }

  @override
  String get noMembersYetGroup => 'Ei jäseniä vielä.';

  @override
  String get groupNameLabel => 'Ryhmän nimi';

  @override
  String get groupNameRequiredError => 'Ryhmän nimi vaaditaan';

  @override
  String get membersLabel => 'Jäsenet';

  @override
  String get noFamilyMembersFoundYet => 'Perheenjäseniä ei löytynyt vielä.';

  @override
  String couldNotSaveGroupError(String error) {
    return 'Ryhmää ei voitu tallentaa — $error';
  }

  @override
  String get freeTimeTitle => 'Vapaa-aika';

  @override
  String get previousDayTooltip => 'Edellinen päivä';

  @override
  String get nextDayTooltip => 'Seuraava päivä';

  @override
  String get minDuration30 => '30 min+';

  @override
  String get minDuration60 => '1 t+';

  @override
  String get minDuration120 => '2 t+';

  @override
  String get couldNotFindMembers => 'Perheenjäseniä ei löytynyt.';

  @override
  String get noFreeWindow =>
      'Ei näin pitkää yhteistä vapaata aikaa klo 7–21 tänä päivänä. Kokeile lyhyempää kestoa tai toista päivää.';

  @override
  String freeForEveryone(int duration) {
    return '$duration minuuttia, vapaata kaikille';
  }

  @override
  String get scheduleButton => 'Ajoita';

  @override
  String scheduleAtTitle(String time) {
    return 'Ajoita klo $time';
  }

  @override
  String couldNotCreateEventError(String error) {
    return 'Tapahtumaa ei voitu luoda — $error';
  }

  @override
  String couldNotLoadFamilyMembersError(String error) {
    return 'Perheenjäseniä ei voitu ladata — $error';
  }

  @override
  String couldNotLoadYourFamilyError(String error) {
    return 'Perhettäsi ei voitu ladata — $error';
  }

  @override
  String couldNotLoadFreeTimeError(String error) {
    return 'Vapaa-aikaa ei voitu ladata — $error';
  }

  @override
  String get familyPulseTitle => 'Family Pulse';

  @override
  String greeting(String name) {
    return 'Hei, $name';
  }

  @override
  String get upcomingStat => 'Tulossa';

  @override
  String get todaysSchedule => 'Tämän päivän ohjelma';

  @override
  String get nothingToday => 'Ei mitään kalenterissa tänään.';

  @override
  String get comingUp => 'Tulossa';

  @override
  String get nothingScheduledYet => 'Ei vielä mitään suunniteltua.';

  @override
  String get jumpTo => 'Siirry';

  @override
  String couldNotLoadPulseError(String error) {
    return 'Sykettäsi ei voitu ladata: $error';
  }

  @override
  String get profileTitle => 'Profiili';

  @override
  String get editProfileButton => 'Muokkaa profiilia';

  @override
  String get yourRoleSubtitle => 'Roolisi perheessä';

  @override
  String get yourLabelSubtitle => 'Nimikkeesi';

  @override
  String get yourFamilySubtitle => 'Perheesi';

  @override
  String get profileUpdated => 'Profiili päivitetty';

  @override
  String couldNotUpdateProfileError(String error) {
    return 'Profiilia ei voitu päivittää — $error';
  }

  @override
  String get changePhotoLabel => 'Vaihda kuva';

  @override
  String get takePhotoOption => 'Ota kuva';

  @override
  String get chooseFromGalleryOption => 'Valitse galleriasta';

  @override
  String get removePhotoOption => 'Poista kuva';

  @override
  String couldNotPickPhotoError(String error) {
    return 'Kuvan valintaa ei voitu avata — $error';
  }

  @override
  String get ageFieldLabel => 'Ikä';

  @override
  String get ageInvalidError => 'Anna ikä väliltä 0–120';

  @override
  String get genderFieldLabel => 'Sukupuoli';

  @override
  String get genderNotSet => 'Ei asetettu';

  @override
  String get genderFemale => 'Nainen';

  @override
  String get genderMale => 'Mies';

  @override
  String get genderOther => 'Muu';

  @override
  String get genderPreferNotToSay => 'En halua kertoa';

  @override
  String get yourAgeSubtitle => 'Ikäsi';

  @override
  String get yourGenderSubtitle => 'Sukupuolesi';

  @override
  String get storageErrorCanceled => 'Kuvan valinta peruutettiin';

  @override
  String get storageErrorUnknown => 'Kuvaa ei voitu ladata. Yritä uudelleen.';

  @override
  String get nameFieldLabel => 'Nimi';

  @override
  String get signOutConfirmTitle => 'Kirjaudutaanko ulos?';

  @override
  String get signOutConfirmContent =>
      'Sinun täytyy kirjautua uudelleen nähdäksesi perheesi kalenterin.';

  @override
  String couldNotSignOutError(String error) {
    return 'Uloskirjautuminen epäonnistui: $error';
  }

  @override
  String get categorySchool => 'Koulu';

  @override
  String get categoryHobby => 'Harrastus';

  @override
  String get categoryWork => 'Työ';

  @override
  String get categoryOther => 'Muu';

  @override
  String get roleParent => 'Vanhempi';

  @override
  String get roleChild => 'Lapsi';

  @override
  String get roleGuardian => 'Huoltaja';

  @override
  String get roleOther => 'Muu';

  @override
  String get myFamilyTitle => 'Perheeni';

  @override
  String get familyGroupsTooltip => 'Perheryhmät';

  @override
  String get membersHeader => 'JÄSENET';

  @override
  String get noMembersFoundYet => 'Jäseniä ei löytynyt vielä.';

  @override
  String couldNotLoadFamilyInfoError(String error) {
    return 'Perhetietoja ei voitu ladata — $error';
  }

  @override
  String couldNotLoadMembersError(String error) {
    return 'Jäseniä ei voitu ladata — $error';
  }

  @override
  String createdOn(String date) {
    return 'Luotu $date';
  }

  @override
  String get copyFamilyCodeTooltip => 'Kopioi perhekoodi';

  @override
  String get familyCodeCopied => 'Perhekoodi kopioitu';

  @override
  String get shareCodeHint => 'Jaa tämä koodi, jotta muut voivat liittyä.';

  @override
  String get youBadge => 'Sinä';

  @override
  String get renameTooltip => 'Nimeä uudelleen';

  @override
  String renameDialogTitle(String name) {
    return 'Nimeä $name uudelleen';
  }

  @override
  String memberUpdated(String name) {
    return '$name päivitetty';
  }

  @override
  String couldNotUpdateMemberError(String error) {
    return 'Jäsentä ei voitu päivittää — $error';
  }

  @override
  String get settingsTitle => 'Asetukset';

  @override
  String get appearanceHeader => 'Ulkoasu';

  @override
  String get systemOption => 'Järjestelmä';

  @override
  String get lightOption => 'Vaalea';

  @override
  String get darkOption => 'Tumma';

  @override
  String get colorThemeLabel => 'Väriteema';

  @override
  String get languageLabel => 'Kieli';

  @override
  String get languageSystemOption => 'Järjestelmä';

  @override
  String get languageEnglishOption => 'English';

  @override
  String get languageFinnishOption => 'Suomi';

  @override
  String get languageSwedishOption => 'Svenska';

  @override
  String get yourNameHeader => 'Nimesi';

  @override
  String get addYourName => 'Lisää nimesi';

  @override
  String get yourFamilyHeader => 'Perheesi';

  @override
  String get familyCodeShareHelper =>
      'Perhekoodi — jaa, jotta muut voivat liittyä';

  @override
  String get calendarHeader => 'Kalenteri';

  @override
  String get showEmptyDaysTitle => 'Näytä tyhjät päivät oletuksena';

  @override
  String get showEmptyDaysSubtitle =>
      'Vaikuttaa seuraavalla kerralla, kun avaat kalenterin — voit silti vaihtaa sitä siellä nopeaa tarkastelua varten.';

  @override
  String get accountHeader => 'Tili';

  @override
  String get nameUpdated => 'Nimi päivitetty';

  @override
  String couldNotUpdateNameError(String error) {
    return 'Nimeä ei voitu päivittää — $error';
  }

  @override
  String get familyCalendarTitle => 'Perhekalenteri';

  @override
  String get hideEmptyDaysTooltip => 'Piilota tyhjät päivät';

  @override
  String get showEmptyDaysTooltip => 'Näytä tyhjät päivät';

  @override
  String get myFamilyTooltip => 'Perheeni';

  @override
  String get couldNotFindFamilyRetryError =>
      'Perhettäsi ei löytynyt vielä — yritä hetken kuluttua uudelleen.';

  @override
  String get deleteEventTitle => 'Poistetaanko tapahtuma?';

  @override
  String deleteEventContent(String title) {
    return '\"$title\" poistetaan kaikilta.';
  }

  @override
  String eventDeleted(String title) {
    return '\"$title\" poistettu';
  }

  @override
  String couldNotDeleteEventError(String error) {
    return 'Tapahtumaa ei voitu poistaa — $error';
  }

  @override
  String get eventAdded => 'Tapahtuma lisätty';

  @override
  String get eventUpdated => 'Tapahtuma päivitetty';

  @override
  String get addEventTooltip => 'Lisää tapahtuma';

  @override
  String get noEventsYet =>
      'Ei vielä tapahtumia — lisää yksi suunnitellaksesi perheaikaa.';

  @override
  String get editEventTooltip => 'Muokkaa tapahtumaa';

  @override
  String get deleteEventTooltip => 'Poista tapahtuma';

  @override
  String get newEventButton => 'Uusi tapahtuma';

  @override
  String get addEventDialogTitle => 'Lisää tapahtuma';

  @override
  String get editEventDialogTitle => 'Muokkaa tapahtumaa';

  @override
  String get categoryLabel => 'Kategoria';

  @override
  String eventTimeLabel(String time) {
    return 'Aika: $time';
  }

  @override
  String couldNotSaveEventError(String error) {
    return 'Tapahtumaa ei voitu tallentaa — $error';
  }

  @override
  String eventsForDate(String date) {
    return 'Tapahtumat $date';
  }

  @override
  String couldNotLoadEventsError(String error) {
    return 'Tapahtumia ei voitu ladata: $error';
  }

  @override
  String get openDayLabel => 'Vapaa';

  @override
  String get analyticsTitle => 'Tilastot';

  @override
  String get noEventsAnalytics =>
      'Ei vielä tapahtumia — tilastot täyttyvät sitä mukaa kun perheesi lisää asioita kalenteriin.';

  @override
  String couldNotLoadAnalyticsError(String error) {
    return 'Tilastoja ei voitu ladata — $error';
  }

  @override
  String get totalEventsStat => 'Tapahtumia yhteensä';

  @override
  String get familyMembersStat => 'Perheenjäseniä';

  @override
  String get next7DaysStat => 'Seuraavat 7 päivää';

  @override
  String get busiestDayTitle => 'Viikon vilkkain päivä';

  @override
  String get mostActiveTitle => 'Kuka on lisännyt eniten';

  @override
  String get noEventsLoggedYet => 'Ei vielä kirjattuja tapahtumia.';

  @override
  String get byCategoryTitle => 'Kategorioittain';

  @override
  String get unknownContributor => 'Tuntematon';

  @override
  String get authErrorWeakPassword =>
      'Salasana on liian heikko. Käytä vähintään 6 merkkiä.';

  @override
  String get authErrorEmailInUse => 'Tällä sähköpostilla on jo tili.';

  @override
  String get authErrorUserNotFound => 'Tällä sähköpostilla ei löytynyt tiliä.';

  @override
  String get authErrorWrongPassword => 'Väärä salasana. Yritä uudelleen.';

  @override
  String get authErrorInvalidEmail => 'Anna kelvollinen sähköpostiosoite.';

  @override
  String get authErrorNotSignedIn =>
      'Sinun täytyy olla kirjautuneena tehdäksesi tämän.';

  @override
  String get authErrorUnknown => 'Jotain meni pieleen. Yritä uudelleen.';

  @override
  String get familyErrorNotFound =>
      'Perhettä ei löytynyt. Tarkista koodi ja yritä uudelleen.';

  @override
  String get recurrenceLabel => 'Toistuu';

  @override
  String get recurrenceNone => 'Ei toistu';

  @override
  String get recurrenceDaily => 'Päivittäin';

  @override
  String get recurrenceWeekly => 'Viikoittain';

  @override
  String get recurrenceMonthly => 'Kuukausittain';

  @override
  String get recurrenceYearly => 'Vuosittain';

  @override
  String get recurrenceNoEndDate => 'Ei päättymispäivää';

  @override
  String recurrenceEndsOn(String date) {
    return 'Päättyy $date';
  }

  @override
  String get recurrenceClearEndDate => 'Poista päättymispäivä';

  @override
  String get partOfRecurringSeriesNote =>
      'Tämä on yksi tapahtuma toistuvasta sarjasta — muokkaus vaikuttaa vain tähän kertaan, ei koko sarjaan.';

  @override
  String get reminderLabel => 'Muistutus';

  @override
  String get reminderOff => 'Ei muistutusta';

  @override
  String get reminderAtEventTime => 'Tapahtuman alkaessa';

  @override
  String reminderMinutesBefore(int minutes) {
    return '$minutes minuuttia ennen';
  }

  @override
  String reminderHoursBefore(int hours) {
    return '$hours tunti ennen';
  }

  @override
  String reminderDaysBefore(int days) {
    return '$days päivä ennen';
  }

  @override
  String reminderNotificationTitle(String title) {
    return 'Tulossa: $title';
  }

  @override
  String reminderNotificationBody(String time) {
    return 'Alkaa klo $time';
  }
}
