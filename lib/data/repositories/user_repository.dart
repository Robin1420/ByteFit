import '../../domain/entities/user.dart';
import '../datasources/local_datasource.dart';

class UserRepository {
  final LocalDataSource _dataSource;

  UserRepository(this._dataSource);

  Future<void> saveUser(User user) async {
    await _dataSource.saveUser(user);
  }

  Future<User?> getUser() async {
    return await _dataSource.getUser();
  }

  Future<void> deleteUser() async {
    await _dataSource.deleteUser();
  }

  Future<void> updateUser(User user) async {
    await _dataSource.saveUser(user);
  }
}
