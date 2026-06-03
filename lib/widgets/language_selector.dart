import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageSelector extends StatelessWidget {
  final bool showLabel;
  final Color? iconColor;
  final Color? textColor;

  const LanguageSelector({
    super.key,
    this.showLabel = true,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.language, color: iconColor ?? Colors.white),
      tooltip: 'Select Language',
      onSelected: (String languageCode) {
        LanguageService.setLocale(languageCode);
      },
      itemBuilder: (BuildContext context) => [
        _buildLanguageItem(context, 'en', 'English', '🇺🇸'),
        _buildLanguageItem(context, 'fr', 'Français', '🇫🇷'),
        _buildLanguageItem(context, 'ar', 'العربية', '🇸🇦'),
      ],
      child: showLabel
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  color: textColor ?? Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  LanguageService.getLanguageName(
                    Localizations.localeOf(context).languageCode,
                  ),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : null,
    );
  }

  PopupMenuItem<String> _buildLanguageItem(
    BuildContext context,
    String code,
    String name,
    String flag,
  ) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isSelected = currentLocale == code;

    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
          ),
          const Spacer(),
          if (isSelected)
            Icon(Icons.check, size: 18, color: Theme.of(context).primaryColor),
        ],
      ),
    );
  }
}

// Simple language switcher for settings or header
class LanguageSwitcher extends StatelessWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;

  const LanguageSwitcher({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: DropdownButton<String>(
        value: Localizations.localeOf(context).languageCode,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: textColor ?? Colors.white),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        items: [
          _buildItem('en', 'English', '🇺🇸'),
          _buildItem('fr', 'Français', '🇫🇷'),
          _buildItem('ar', 'العربية', '🇸🇦'),
        ],
        onChanged: (String? languageCode) {
          if (languageCode != null) {
            LanguageService.setLocale(languageCode);
          }
        },
        selectedItemBuilder: (BuildContext context) {
          return [
            _buildSelectedItem('English', textColor ?? Colors.white),
            _buildSelectedItem('Français', textColor ?? Colors.white),
            _buildSelectedItem('العربية', textColor ?? Colors.white),
          ];
        },
      ),
    );
  }

  DropdownMenuItem<String> _buildItem(String code, String name, String flag) {
    return DropdownMenuItem<String>(
      value: code,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }

  Widget _buildSelectedItem(String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
