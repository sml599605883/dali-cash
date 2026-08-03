import '../../../core/json/json.dart';
import '../personal_information/personal_information_data.dart';

class EmergencyContactOption {
  const EmergencyContactOption({required this.label, required this.value});

  factory EmergencyContactOption.fromJson(Json json) {
    return EmergencyContactOption(
      label: json['crocidolites'].stringValue.trim(),
      value: json['sociologeses'].stringValue.trim(),
    );
  }

  final String label;
  final String value;
}

class EmergencyContact {
  const EmergencyContact({
    required this.number,
    required this.relationshipValue,
    required this.relationshipLabel,
    required this.name,
    required this.phone,
    required this.relationshipOptions,
  });

  factory EmergencyContact.fromJson(Json json) {
    final options = json['microbial'].listValue
        .map(EmergencyContactOption.fromJson)
        .where((item) => item.label.isNotEmpty && item.value.isNotEmpty)
        .toList(growable: false);
    final relationshipValue = json['roebuck'].stringValue.trim();
    final selected = options
        .where((item) => item.value == relationshipValue)
        .firstOrNull;
    return EmergencyContact(
      number: json['attractances'].stringValue.trim(),
      relationshipValue: relationshipValue,
      relationshipLabel: selected?.label ?? '',
      name: json['crocidolites'].stringValue.trim(),
      phone: json['poet'].stringValue.trim(),
      relationshipOptions: options,
    );
  }

  final String number;
  final String relationshipValue;
  final String relationshipLabel;
  final String name;
  final String phone;
  final List<EmergencyContactOption> relationshipOptions;
}

class EmergencyContactData {
  const EmergencyContactData({required this.prompt, required this.contacts});

  factory EmergencyContactData.fromJson(Json json) {
    final payload = json['silentnesses'].exists() ? json : json['unsphered'];
    return EmergencyContactData(
      prompt: payload['dextrorse'].stringValue.trim(),
      contacts: payload['silentnesses']['clingiest'].listValue
          .map(EmergencyContact.fromJson)
          .where((contact) => contact.number.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String prompt;
  final List<EmergencyContact> contacts;

  PersonalInformationData toFormData() {
    return PersonalInformationData(
      prompt: prompt,
      fields: [for (final contact in contacts) ..._fields(contact)],
    );
  }

  static List<Map<String, String>> contactsFromFields(
    Map<String, String> fields,
  ) {
    final numbers = <String>[];
    for (final key in fields.keys) {
      if (!key.endsWith('.roebuck')) continue;
      numbers.add(key.substring(0, key.length - '.roebuck'.length));
    }
    return numbers
        .where((number) => number.isNotEmpty)
        .map(
          (number) => {
            'poet': fields['$number.poet'] ?? '',
            'crocidolites': fields['$number.crocidolites'] ?? '',
            'roebuck': fields['$number.roebuck'] ?? '',
            'attractances': number,
          },
        )
        .toList(growable: false);
  }

  static List<PersonalInformationField> _fields(EmergencyContact contact) {
    final number = contact.number;
    return [
      PersonalInformationField(
        title: 'Relationship',
        placeholder: 'Please select relationship',
        saveKey: '$number.roebuck',
        control: PersonalInformationControl.selection,
        numericKeyboard: false,
        isRequired: true,
        options: contact.relationshipOptions
            .map(
              (option) => PersonalInformationOption(
                label: option.label,
                value: option.value,
              ),
            )
            .toList(growable: false),
        initialDisplayValue: contact.relationshipLabel,
        initialSubmitValue: contact.relationshipValue,
      ),
      PersonalInformationField(
        title: 'Contact Information',
        placeholder: 'Please enter contact name',
        saveKey: '$number.crocidolites',
        control: PersonalInformationControl.text,
        numericKeyboard: false,
        isRequired: true,
        options: const [],
        initialDisplayValue: contact.name,
        initialSubmitValue: contact.name,
      ),
      PersonalInformationField(
        title: 'telephone number',
        placeholder: 'Please enter telephone number',
        saveKey: '$number.poet',
        control: PersonalInformationControl.text,
        numericKeyboard: true,
        isRequired: true,
        options: const [],
        initialDisplayValue: contact.phone,
        initialSubmitValue: contact.phone,
      ),
    ];
  }
}
