import 'package:receyta/data/space/space_remote.dart';

/// A casa em memória: nada de rede. `space` é o que o servidor diz da casa de
/// quem está logado; `failWith` faz a próxima operação lançar esse erro.
class FakeSpaceRemote implements SpaceRemote {
  FakeSpaceRemote({this.space, this.userId = 'ana'});

  SpaceInfo? space;
  Object? failWith;
  int inviteCalls = 0;
  int leaveCalls = 0;
  final removed = <String>[];

  @override
  String? userId;

  void _maybeFail() {
    final e = failWith;
    if (e != null) {
      failWith = null;
      throw e;
    }
  }

  SpaceInfo _house(String name) => SpaceInfo(
        id: 'casa-1',
        name: 'Casa',
        ownerId: userId!,
        members: [
          SpaceMember(userId: userId!, displayName: name, isOwner: true),
        ],
      );

  @override
  Future<SpaceInfo?> mySpace() async {
    _maybeFail();
    return space;
  }

  @override
  Future<SpaceInfo> createSpace(String displayName) async {
    _maybeFail();
    return space = _house(displayName);
  }

  @override
  Future<String> createInvite() async {
    _maybeFail();
    inviteCalls++;
    return 'ABCD1234';
  }

  @override
  Future<SpaceInfo> joinSpace(String code, String displayName) async {
    _maybeFail();
    return space = SpaceInfo(
      id: 'casa-1',
      name: 'Casa',
      ownerId: 'dono',
      members: [
        const SpaceMember(userId: 'dono', displayName: 'Dono', isOwner: true),
        SpaceMember(userId: userId!, displayName: displayName, isOwner: false),
      ],
    );
  }

  @override
  Future<void> leaveSpace() async {
    _maybeFail();
    leaveCalls++;
    space = null;
  }

  @override
  Future<void> removeMember(String userId) async {
    _maybeFail();
    removed.add(userId);
  }

  final sharePrefs = <String, bool>{};

  @override
  Future<void> setSharePref(String key, bool on) async {
    _maybeFail();
    sharePrefs[key] = on;
  }

  final names = <String>[];
  final renamed = <String>[];
  final transferred = <String>[];

  @override
  Future<void> renameSpace(String name) async {
    _maybeFail();
    renamed.add(name);
    final s = space;
    if (s == null) return;
    space = SpaceInfo(
      id: s.id,
      name: name,
      ownerId: s.ownerId,
      members: s.members,
    );
  }

  @override
  Future<void> transferOwnership(String userId) async {
    _maybeFail();
    transferred.add(userId);
    final s = space;
    if (s == null) return;
    space = SpaceInfo(
      id: s.id,
      name: s.name,
      ownerId: userId,
      members: [
        for (final m in s.members)
          SpaceMember(
            userId: m.userId,
            displayName: m.displayName,
            isOwner: m.userId == userId,
          ),
      ],
    );
  }

  @override
  Future<void> setDisplayName(String name) async {
    _maybeFail();
    names.add(name);
    final s = space;
    if (s == null) return;
    space = SpaceInfo(
      id: s.id,
      name: s.name,
      ownerId: s.ownerId,
      members: [
        for (final m in s.members)
          m.userId == userId
              ? SpaceMember(
                  userId: m.userId,
                  displayName: name,
                  isOwner: m.isOwner,
                )
              : m,
      ],
    );
  }
}
