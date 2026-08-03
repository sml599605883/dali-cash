import '../../core/json/json.dart';

class AccountListSection {
  AccountListSection({
    required this.cardType,
    required this.title,
    required this.typeIconUrl,
    required List<AccountListItem> accounts,
  }) : accounts = List.unmodifiable(accounts);

  final String cardType;
  final String title;
  final String typeIconUrl;
  final List<AccountListItem> accounts;
}

class AccountListItem {
  const AccountListItem({
    required this.bindId,
    required this.type,
    required this.logoUrl,
    required this.providerName,
    required this.accountValue,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.isMain,
    required this.isUnderMaintenance,
  });

  final String bindId;
  final String type;
  final String logoUrl;
  final String providerName;
  final String accountValue;
  final String firstName;
  final String middleName;
  final String lastName;
  final bool isMain;
  final bool isUnderMaintenance;
}

List<AccountListSection> parseAccountSections(Json states) {
  final sections = <AccountListSection>[];

  for (final sectionJson in states['clingiest'].listValue) {
    final title = sectionJson['pater'].stringValue.trim();
    if (title.isEmpty) {
      continue;
    }

    final accounts = <AccountListItem>[];
    for (final accountJson in sectionJson['jambes'].listValue) {
      final bindId = accountJson['hoover'].stringValue.trim();
      if (bindId.isEmpty) {
        continue;
      }

      final option = accountJson['nonbehavioral'];
      accounts.add(
        AccountListItem(
          bindId: bindId,
          type: accountJson['sociologeses'].stringValue.trim(),
          logoUrl: accountJson['leachate'].stringValue.trim(),
          providerName: accountJson['filmcards'].stringValue.trim(),
          accountValue: accountJson['emptiable'].stringValue.trim(),
          firstName: option['rattlesnakes'].stringValue.trim(),
          middleName: option['monerans'].stringValue.trim(),
          lastName: option['sloid'].stringValue.trim(),
          isMain: accountJson['exploitable'].boolValue,
          isUnderMaintenance: _isExactZero(accountJson['precolonial']),
        ),
      );
    }

    if (accounts.isEmpty) {
      continue;
    }

    sections.add(
      AccountListSection(
        cardType: sectionJson['rapscallion'].stringValue.trim(),
        title: title,
        typeIconUrl: sectionJson['alodia'].stringValue.trim(),
        accounts: accounts,
      ),
    );
  }

  return List.unmodifiable(sections);
}

bool _isExactZero(Json json) {
  final value = json.value;
  if (value is bool) {
    return false;
  }
  if (value is num) {
    return value == 0;
  }
  if (value is String) {
    return num.tryParse(value.trim()) == 0;
  }
  return false;
}
