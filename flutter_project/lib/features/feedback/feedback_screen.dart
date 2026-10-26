import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../core/services/feedback_service.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';

/// FeedbackScreen — optional message form for support and data corrections.
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
    (label: 'Data Correction', value: 'data'),
    (label: 'Other', value: 'other'),
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _location.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final sent = await FeedbackService.instance.submit(
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
        title: Text(sent ? 'Thank you!' : 'Could not send feedback'),
        content: Text(
          sent
              ? 'Your feedback has been sent.'
              : 'Please check your connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (sent) Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            const AppPageHeader(
              title: 'Send Feedback',
              subtitle: 'We read every message',
              bottomRadius: 36,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  key: const Key('feedback-form-list'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    Tokens.spaceMd,
                    AppSpacing.screen,
                    Tokens.spaceXl,
                  ),
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
                    const Text('Type'),
                    const SizedBox(height: Tokens.spaceSm),
                    Wrap(
                      spacing: Tokens.spaceSm,
                      runSpacing: Tokens.spaceSm,
                      children: [
                        for (final type in _types)
                          _TypeChip(
                            label: type.label,
                            selected: _type == type.value,
                            onTap: () => setState(() => _type = type.value),
                          ),
                      ],
                    ),
                    const SizedBox(height: Tokens.spaceMd),
                    _Field(
                      controller: _comment,
                      label: 'Comment',
                      hint: 'Tell us what happened',
                      required: true,
                      maxLines: 5,
                    ),
                    const SizedBox(height: Tokens.spaceLg),
                    AppButton(
                      key: const Key('feedback-submit'),
                      label: _submitting ? 'Sending…' : 'Submit',
                      enabled: !_submitting,
                      loading: _submitting,
                      icon: _submitting ? null : AppIcons.send,
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
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
            ],
          ),
          style: TextStyle(
            fontSize: Tokens.fontSm,
            fontWeight: FontWeight.w800,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 5),
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
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: 'Feedback type: $label',
      borderRadius: BorderRadius.circular(Tokens.shapePill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.spaceSm,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? palette.primary : palette.surfaceTint,
          borderRadius: BorderRadius.circular(Tokens.shapePill),
          border: Border.all(
            color: selected ? palette.primary : palette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Tokens.fontSm,
            fontWeight: FontWeight.w800,
            color: selected ? palette.onPrimary : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
