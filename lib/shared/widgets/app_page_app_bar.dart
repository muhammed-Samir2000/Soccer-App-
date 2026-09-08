import 'package:flutter/material.dart';

class AppPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageAppBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.showBack = true,
  });

  final String title;
  final List<Widget> actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(title),
      actions: <Widget>[...actions, if (showBack) const _AppBackButton()],
    );
  }
}

class _AppBackButton extends StatelessWidget {
  const _AppBackButton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'رجوع للشاشة السابقة',
    button: true,
    child: IconButton(
      tooltip: 'رجوع',
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back),
    ),
  );
}
