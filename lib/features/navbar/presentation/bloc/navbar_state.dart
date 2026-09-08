enum UserRole { citizen, employee }

class NavbarState {
  const NavbarState({
    this.currentTabIndex = 0,
    this.role = UserRole.citizen,
  });
  final int currentTabIndex;
  final UserRole role;

  NavbarState copyWith({
    int? currentTabIndex,
    UserRole? role,
  }) {
    return NavbarState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      role: role ?? this.role,
    );
  }
}
