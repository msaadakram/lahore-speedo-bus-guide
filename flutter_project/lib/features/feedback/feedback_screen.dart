import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_tokens.dart';
import '../../core/services/feedback_service.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';

/// FeedbackScreen (Metro module 1082).
///
/// The original wrote to the Firestore top-level collection `feedback` with
/// fields `name`, `email`, `location`, `type`, `comment`, `platform:'android'`
/// and `createdAt: serverTimestamp()`. The rebuild sends the same payload to a
/// configurable REST backend (see `.env.example`) and keeps it working offline.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _location = TextEditingController();
  final _comment = TextEditingController();
  String _type = 'suggestion';
  bool _submitting = false;

  static const _types = <({String label, String value})>[
    (label: 'Bug Report', value: 'bug'),
    (label: 'Suggestion', value: 'suggestion'),
    (label: 'Complaint', value: 'complaint'),
    (label: 'Feature Request', value: 'feature'),
    (label: 'Route / Stop Data Correction', value: 'data'),
    (label: 'Other', value: 'other'),
  ];

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final ok = await FeedbackService.instance.submit(
      FeedbackPayload(
        name: _name.text.trim(),
        email: _email.text.trim(),
        location: _location.text.trim(),
        type: _type,
        comment: _comment.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ok ? 'Thank you!' : 'Could not send feedback'),
        content: Text(
          ok
              ? 'Your feedback has been sent.'
              : 'Please check your connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (ok) Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);

    return Scaffold(
      body: ColoredBox(
        color: palette.background,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                boxShadow: palette.softShadow,
              ),
              padding: EdgeInsets.only(
                left: Tokens.spaceMd,
                right: Tokens.spaceMd,
                top: insets.top + Tokens.spaceSm,
                bottom: Tokens.spaceSm,
              ),
              child: Row(
                children: [
                  AppPressable(
                    onPressed: () => Navigator.of(context).pop(),
                    borderless: true,
                    rippleColor: Colors.white,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        AppIcons.arrowLeft,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send Feedback',
                          style: TextStyle(
                            fontSize: Tokens.fontXl,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'We read every message',
                          style: TextStyle(
                            fontSize: Tokens.fontSm,
                            color: Color(0xE6FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  key: const Key('feedback-form-list'),
                  padding: const EdgeInsets.all(Tokens.spaceMd),
                  children: [
                    _Field(
                      controller: _name,
                      label: 'Your Name',
                      hint: 'Your name',
                      required: true,
                    ),
                    const SizedBox(height: Tokens.spaceMd),
                    _Field(
                      controller: _email,
                      label: 'Email',
                      hint: 'you@example.com',
                      required: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: Tokens.spaceMd),
                    _Field(
                      controller: _location,
                      label: 'Location',
                      hint: 'Area / stop',
                      required: true,
                    ),
                    const SizedBox(height: Tokens.spaceMd),
                    _Dropdown(
                      label: 'Type',
                      value: _type,
                      items: _types,
                      onChanged: (v) =>
                          setState(() => _type = v ?? 'suggestion'),
                    ),
                    const SizedBox(height: Tokens.spaceMd),
                    _Field(
                      controller: _comment,
                      label: 'Comment',
                      hint: 'Tell us what happened',
                      required: true,
                      maxLines: 4,
                    ),
                    const SizedBox(height: Tokens.spaceLg),
                    AppButton(
                      key: const Key('feedback-submit'),
                      label: 'Submit',
                      enabled: !_submitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.required = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The original renders the label and the required marker as two
        // sibling Texts: [label]['' | ' *'].
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: Tokens.fontSm,
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
            Text(
              required ? ' *' : '',
              style: TextStyle(
                fontSize: Tokens.fontSm,
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (required && text.isEmpty) return 'Required';
            if (label.startsWith('Email') &&
                text.isNotEmpty &&
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
              return 'Enter a valid email address.';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            errorStyle: const TextStyle(
              color: Color(0xFFC62828),
              fontSize: Tokens.fontXs,
            ),
          ),
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<({String label, String value})> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Tokens.fontSm,
            fontWeight: FontWeight.w700,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          items: items
              .map(
                (t) => DropdownMenuItem(value: t.value, child: Text(t.label)),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) => (v == null || v.isEmpty) ? 'Select a type' : null,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}
