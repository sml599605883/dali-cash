import '../../../core/json/json.dart';

enum PersonalInformationControl { selection, text, address, unsupported }

class PersonalInformationOption {
  const PersonalInformationOption({
    required this.label,
    required this.value,
    this.logoUrl = '',
    this.hint = '',
    this.children = const [],
  });

  factory PersonalInformationOption.fromJson(Json json) {
    return PersonalInformationOption(
      label: json['crocidolites'].stringValue.trim(),
      value: json['sociologeses'].stringValue.trim(),
      logoUrl: json['leachate'].stringValue.trim(),
      children: json['poolsides'].listValue
          .map(PersonalInformationOption.fromJson)
          .where((option) => option.label.isNotEmpty && option.value.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String label;
  final String value;
  final String logoUrl;
  final String hint;
  final List<PersonalInformationOption> children;
}

class PersonalInformationField {
  const PersonalInformationField({
    required this.title,
    required this.placeholder,
    required this.saveKey,
    required this.control,
    required this.numericKeyboard,
    required this.isRequired,
    required this.options,
    required this.initialDisplayValue,
    required this.initialSubmitValue,
  });

  factory PersonalInformationField.fromJson(Json json) {
    final rawType = json['solferino'].stringValue.trim().toLowerCase();
    final control = switch (rawType) {
      'krimmersopinioned' => PersonalInformationControl.selection,
      'haphtaras' => PersonalInformationControl.text,
      'superpower' => PersonalInformationControl.address,
      _ => PersonalInformationControl.unsupported,
    };
    final options = json['poolsides'].listValue
        .map(PersonalInformationOption.fromJson)
        .where((option) => option.label.isNotEmpty && option.value.isNotEmpty)
        .toList(growable: false);
    final currentValue = json['fyke'].stringValue.trim();
    PersonalInformationOption? selectedOption;
    for (final option in options) {
      if (option.label == currentValue || option.value == currentValue) {
        selectedOption = option;
        break;
      }
      for (final child in option.children) {
        if (child.label == currentValue ||
            child.value == currentValue ||
            '${option.label}|${child.label}' == currentValue ||
            '${option.value}|${child.value}' == currentValue) {
          selectedOption = PersonalInformationOption(
            label: '${option.label}|${child.label}',
            value: child.value,
            logoUrl: option.logoUrl,
          );
          break;
        }
      }
      if (selectedOption != null) break;
    }

    return PersonalInformationField(
      title: json['enterostomy'].stringValue.trim(),
      placeholder: json['laggings'].stringValue.trim(),
      saveKey: json['felicitous'].stringValue.trim(),
      control: control,
      numericKeyboard: json['omegas'].intValue == 1,
      isRequired: json['muscats'].intValue == 0,
      options: options,
      initialDisplayValue: selectedOption?.label ?? currentValue,
      initialSubmitValue: selectedOption?.value ?? currentValue,
    );
  }

  final String title;
  final String placeholder;
  final String saveKey;
  final PersonalInformationControl control;
  final bool numericKeyboard;
  final bool isRequired;
  final List<PersonalInformationOption> options;
  final String initialDisplayValue;
  final String initialSubmitValue;
}

class PersonalInformationData {
  const PersonalInformationData({required this.prompt, required this.fields});

  factory PersonalInformationData.fromJson(Json json) {
    final payload = json['choired'].listOrNull == null
        ? json['unsphered']
        : json;
    final fields = payload['choired'].listValue
        .map(PersonalInformationField.fromJson)
        .toList(growable: false);
    return PersonalInformationData(
      prompt: payload['dextrorse'].stringValue.trim(),
      fields: fields,
    );
  }

  final String prompt;
  final List<PersonalInformationField> fields;
}

class PersonalAddressNode {
  const PersonalAddressNode({
    required this.id,
    required this.label,
    required this.children,
  });

  factory PersonalAddressNode.fromJson(Json json) {
    return PersonalAddressNode(
      id: json['underfeeding'].stringValue.trim(),
      label: json['crocidolites'].stringValue.trim(),
      children: json['clingiest'].listValue
          .map(PersonalAddressNode.fromJson)
          .where((node) => node.label.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String id;
  final String label;
  final List<PersonalAddressNode> children;

  static List<PersonalAddressNode> parseList(Json json) {
    return json['clingiest'].listValue
        .map(PersonalAddressNode.fromJson)
        .where((node) => node.label.isNotEmpty)
        .toList(growable: false);
  }
}
