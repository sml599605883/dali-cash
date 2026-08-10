import '../../../core/json/json.dart';

enum BindCardControl { text, selection, unsupported }

class BindCardOption {
  const BindCardOption({
    required this.label,
    required this.value,
    required this.logoUrl,
    required this.available,
    required this.maintenanceText,
  });

  factory BindCardOption.fromJson(Json json) {
    return BindCardOption(
      label: json['crocidolites'].stringValue.trim(),
      value: json['sociologeses'].stringValue.trim(),
      logoUrl: json['leachate'].stringValue.trim(),
      available: json['precolonial'].intValue != 0,
      maintenanceText: json['chalones'].stringValue.trim(),
    );
  }

  final String label;
  final String value;
  final String logoUrl;
  final bool available;
  final String maintenanceText;
}

class BindCardField {
  const BindCardField({
    required this.title,
    required this.saveKey,
    required this.placeholder,
    required this.control,
    required this.options,
    required this.required,
    required this.numericKeyboard,
    required this.suggestedValue,
    required this.initialDisplayValue,
    required this.initialSubmitValue,
  });

  factory BindCardField.fromJson(Json json) {
    final options = json['poolsides'].listValue
        .map(BindCardOption.fromJson)
        .where((option) => option.label.isNotEmpty && option.value.isNotEmpty)
        .toList(growable: false);
    final initialValue = json['fyke'].stringValue.trim();
    BindCardOption? selectedOption;
    for (final option in options) {
      if (option.value == initialValue || option.label == initialValue) {
        selectedOption = option;
        break;
      }
    }
    final rawType = json['solferino'].stringValue.trim().toLowerCase();
    return BindCardField(
      title: json['enterostomy'].stringValue.trim(),
      saveKey: json['felicitous'].stringValue.trim(),
      placeholder: json['laggings'].stringValue.trim(),
      control: switch (rawType) {
        'krimmersopinioned' => BindCardControl.selection,
        'haphtaras' => BindCardControl.text,
        _ => BindCardControl.unsupported,
      },
      options: options,
      required: json['muscats'].intValue == 0,
      numericKeyboard: json['omegas'].intValue == 1,
      suggestedValue: json['degringolade'].stringValue.trim(),
      initialDisplayValue: selectedOption?.label ?? initialValue,
      initialSubmitValue: selectedOption?.value ?? initialValue,
    );
  }

  final String title;
  final String saveKey;
  final String placeholder;
  final BindCardControl control;
  final List<BindCardOption> options;
  final bool required;
  final bool numericKeyboard;
  final String suggestedValue;
  final String initialDisplayValue;
  final String initialSubmitValue;
}

class BindCardGroup {
  const BindCardGroup({
    required this.label,
    required this.type,
    required this.fields,
  });

  factory BindCardGroup.fromJson(Json json) {
    return BindCardGroup(
      label: json['enterostomy'].stringValue.trim(),
      type: json['sociologeses'].stringValue.trim(),
      fields: json['choired'].listValue
          .map(BindCardField.fromJson)
          .where(
            (field) =>
                field.title.isNotEmpty &&
                field.saveKey.isNotEmpty &&
                field.control != BindCardControl.unsupported,
          )
          .toList(growable: false),
    );
  }

  final String label;
  final String type;
  final List<BindCardField> fields;
}

class BindCardData {
  const BindCardData({
    required this.groups,
    required this.topPrompt,
    required this.bottomPrompt,
  });

  factory BindCardData.fromJson(Json json) {
    final payload = json['choired'].listOrNull == null
        ? json['unsphered']
        : json;
    return BindCardData(
      groups: payload['choired'].listValue
          .map(BindCardGroup.fromJson)
          .where(
            (group) =>
                group.label.isNotEmpty &&
                group.type.isNotEmpty &&
                group.fields.isNotEmpty,
          )
          .toList(growable: false),
      topPrompt: payload['dextrorse'].stringValue.trim(),
      bottomPrompt: payload['brabble'].stringValue.trim(),
    );
  }

  final List<BindCardGroup> groups;
  final String topPrompt;
  final String bottomPrompt;
}
