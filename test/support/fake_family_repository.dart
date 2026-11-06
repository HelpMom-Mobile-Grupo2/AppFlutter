import 'package:helpmom_companion/features/family/data/family_api.dart';
import 'package:helpmom_companion/features/family/data/family_models.dart';
import 'package:helpmom_companion/features/family/data/family_repository.dart';

final sampleFamily = FamilyGroup(
  id: 'g1',
  name: 'Familia de Daniela Gómez',
  members: [
    FamilyMember(
      userId: 'm1',
      fullName: 'Daniela Gómez',
      role: MemberRole.mother,
      joinedAt: DateTime.utc(2026, 11, 1),
    ),
    FamilyMember(
      userId: 'u1',
      fullName: 'Carlos Ruiz',
      role: MemberRole.partner,
      joinedAt: DateTime.utc(2026, 11, 2),
    ),
  ],
);

/// Repositorio de prueba: devuelve [family] o lanza [error].
class FakeFamilyRepository implements FamilyRepository {
  FakeFamilyRepository({FamilyGroup? family}) : family = family ?? sampleFamily;

  FamilyGroup? family;
  Object? error;

  // El fake no usa la API.
  @override
  FamilyApi get api => throw UnimplementedError();

  @override
  Future<FamilyGroup?> getFamily() async {
    if (error != null) throw error!;
    return family;
  }

  @override
  Future<JoinFamilyResult> join(String code) async =>
      const JoinFamilyResult(familyGroupId: 'g1', motherName: 'Daniela Gómez');
}
