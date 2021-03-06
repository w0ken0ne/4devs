import 'package:faker/faker.dart';
import 'package:fordevs/data/http/http_error.dart';
import 'package:fordevs/data/models/remote_account_model.dart';
import 'package:fordevs/domain/entities/account_entity.dart';
import 'package:fordevs/domain/helpers/domain_error.dart';
import 'package:fordevs/domain/usecases/usecases.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:meta/meta.dart';

class RemoteAuthentication {
  final HttpClient httpClient;
  final String url;

  RemoteAuthentication({@required this.httpClient, @required this.url});
  Future<AccountEntity> auth(AuthenticationParams params) async {
    final body = RemoteAuthenticationParams.fromDomain(params).toJson();
    try {
      final httpResponse =
          await httpClient.request(url: url, method: 'post', body: body);
      return RemoteAccountModel.fromJson(httpResponse).toEntity();
    } on HttpError catch (e) {
      throw e == HttpError.unauthorized
          ? DomainError.invalidCredentials
          : DomainError.unexpected;
    }
  }
}

class HttpClient {
  Future<Map> request(
      {@required String url, @required String method, Map body}) async {}
}

class HttpClientSpy extends Mock implements HttpClient {}

class RemoteAuthenticationParams {
  final String email;
  final String password;

  RemoteAuthenticationParams({@required this.email, @required this.password});
  Map toJson() => {
        'email': email,
        'password': password,
      };
  factory RemoteAuthenticationParams.fromDomain(AuthenticationParams params) =>
      RemoteAuthenticationParams(email: params.email, password: params.secret);
}

void main() {
  HttpClientSpy httpClient;
  String url;
  RemoteAuthentication sut;
  AuthenticationParams params;
  PostExpectation mockRequest() => when(httpClient.request(
      url: anyNamed("url"),
      method: anyNamed('method'),
      body: anyNamed('body')));
  Map mockValidData() =>
      {'accessToken': faker.guid.guid(), 'name': faker.person.name()};
  void mockHttpData(Map data) {
    mockRequest().thenAnswer((_) async => data);
  }

  void mockHttpError(HttpError error) {
    mockRequest().thenThrow(error);
  }

  setUp(() {
    httpClient = HttpClientSpy();
    url = faker.internet.httpUrl();
    sut = RemoteAuthentication(httpClient: httpClient, url: url);
    params = AuthenticationParams(
        email: faker.internet.email(), secret: faker.internet.password());
    mockHttpData(mockValidData());
  });

  test('should call httpClient with correct values', () async {
    //arrange
    //act
    await sut.auth(params);
    //assert
    verify(httpClient.request(url: url, method: 'post', body: {
      'email': params.email,
      'password': params.secret,
    }));
  });
  test('should call httpClient with correct body', () async {
    //arrange

    //act
    await sut.auth(params);
    //assert
    verify(httpClient.request(url: url, method: 'post', body: {
      'email': params.email,
      'password': params.secret,
    }));
  });
  test('should throw UnexpectedError if HttpClient return 400', () async {
    //arrange
    mockHttpError(HttpError.badRequest);
    //act
    final future = sut.auth(params);
    //assert
    expect(future, throwsA(DomainError.unexpected));
  });
  test('should return UnexpectedError if HttpClient returns 404', () async {
    //arrange
    mockHttpError(HttpError.notFound);
    //act
    final future = sut.auth(params);

    //assert
    expect(future, throwsA(DomainError.unexpected));
  });
  test('should return UnexpectedError if HttpClient returns 500', () async {
    //arrange
    mockHttpError(HttpError.serverError);
    //act
    final future = sut.auth(params);

    //assert
    expect(future, throwsA(DomainError.unexpected));
  });
  test('should return InvalidCredentials if HttpClient returns 401', () async {
    //arrange
    mockHttpError(HttpError.unauthorized);
    //act
    final future = sut.auth(params);

    //assert
    expect(future, throwsA(DomainError.invalidCredentials));
  });
  test('should return an Account if httpClient returns 200', () async {
    //arrange
    final validData = mockValidData();
    mockHttpData(validData);
    //act
    final account = await sut.auth(params);
    //assert
    expect(account.token, validData['accessToken']);
  });
  test(
      'should throw UnexpectedError if HttpClient returns 200 with invalid data',
      () async {
    //arrange
    mockHttpData({'invalid_key': 'invalid_value'});

    //act
    final future = sut.auth(params);
    //assert
    expect(future, throwsA(DomainError.unexpected));
  });
}
