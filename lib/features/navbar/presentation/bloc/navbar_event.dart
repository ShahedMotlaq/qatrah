abstract class NavbarEvent {}

class ChangeBottomNavTabEvent extends NavbarEvent {
  ChangeBottomNavTabEvent(this.index);

  final int index;
}
